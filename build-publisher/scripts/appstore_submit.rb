# Attaches a processed build to the app's App Store version and submits it for review.
#
#   bundle exec ruby appstore_submit.rb <bundleId> <keyId> <issuerId> <keyPath> <versionString> <buildNumber>
#
# The same steps deliver's submit_for_review takes, without deliver's metadata upload:
# the listing is managed separately. Anything App Store Connect still needs (screenshots,
# privacy answers, export compliance…) comes back as its own error message.
require "spaceship"

bundle_id, key_id, issuer_id, key_path, version_string, build_number = ARGV
abort("usage: appstore_submit.rb <bundleId> <keyId> <issuerId> <keyPath> <version> <build>") unless build_number

Spaceship::ConnectAPI.auth(key_id: key_id, issuer_id: issuer_id, filepath: key_path)
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
