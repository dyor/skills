# Attaches a processed build to the app's App Store version and submits it for review.
#
#   bundle exec ruby appstore_submit.rb <bundleId> <keyId> <issuerId> <keyPath> <versionString> <buildNumber> [whatsNewFile]
#
# An update must have "What's New in This Version" text in every language, or Apple refuses
# the submission ("You must provide a value for the attribute 'whatsNew'"). Any language
# without it gets the text of whatsNewFile (the release notes written for this build).
#
# The same steps deliver's submit_for_review takes, without deliver's metadata upload:
# the listing is managed separately. Anything App Store Connect still needs (screenshots,
# privacy answers, export compliance…) comes back as its own error message.
require "spaceship"

bundle_id, key_id, issuer_id, key_path, version_string, build_number, whats_new_file = ARGV
abort("usage: appstore_submit.rb <bundleId> <keyId> <issuerId> <keyPath> <version> <build> [whatsNewFile]") unless build_number

Spaceship::ConnectAPI.auth(key_id: key_id, issuer_id: issuer_id, filepath: File.expand_path(key_path))
app = Spaceship::ConnectAPI::App.find(bundle_id) or abort("No app for #{bundle_id} in App Store Connect")
platform = Spaceship::ConnectAPI::Platform::IOS

# In spaceship `version` filters by the marketing version (1.0); the build number is `build_number`.
build = Spaceship::ConnectAPI::Build.all(app_id: app.id, version: version_string, build_number: build_number).first
abort("Build #{build_number} isn't in App Store Connect yet") unless build
abort("Build #{build_number} is still #{build.processing_state} — try again when it's VALID") unless build.processing_state == "VALID"

version = app.get_edit_app_store_version(platform: platform)
if version.nil?
  puts "creating App Store version #{version_string}"
  Spaceship::ConnectAPI.post_app_store_version(app_id: app.id, attributes: { versionString: version_string, platform: platform })
  version = app.get_edit_app_store_version(platform: platform)
elsif version.version_string != version_string
  puts "renaming editable version #{version.version_string} -> #{version_string}"
  version.update(attributes: { versionString: version_string })
end
abort("Couldn't get an editable App Store version") unless version

puts "attaching build #{build_number} to version #{version_string}"
version.select_build(build_id: build.id)

# The first version of an app has no "What's New"; every later one needs it.
first_version = app.get_app_store_versions(filter: { platform: platform }).none? { |v| v.id != version.id }
whats_new = whats_new_file && File.exist?(whats_new_file) ? File.read(whats_new_file).strip : ""
whats_new = "Bug fixes and improvements." if whats_new.empty?
whats_new = whats_new[0, 4000]
unless first_version
  version.get_app_store_version_localizations.each do |loc|
    next unless loc.whats_new.to_s.strip.empty?
    puts "setting What's New (#{loc.locale}): #{whats_new.lines.first.to_s.strip}#{whats_new.lines.count > 1 ? " …" : ""}"
    loc.update(attributes: { whatsNew: whats_new })
  end
end

submission = app.get_ready_review_submission(platform: platform, includes: "items")
submission ||= app.create_review_submission(platform: platform)
unless submission.items&.any? { |i| i.app_store_version&.id == version.id }
  submission.add_app_store_version_to_review_items(app_store_version_id: version.id)
end

begin
  submission.submit_for_review
rescue => e
  # App Store Connect lists everything that is missing in one error; show it whole.
  abort("App Store Connect refused the submission:\n#{e.message}")
end
puts "submitted #{version_string} (#{build_number}) for App Review"
