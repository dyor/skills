# Waits for an uploaded build to finish processing in App Store Connect, then sets its
# TestFlight "What to Test" text (en-US).
#
#   bundle exec ruby appstore_notes.rb <bundleId> <keyId> <issuerId> <keyPath> <buildNumber> <notesFile>
require "spaceship"

bundle_id, key_id, issuer_id, key_path, build_number, notes_file = ARGV
Spaceship::ConnectAPI.auth(key_id: key_id, issuer_id: issuer_id, filepath: File.expand_path(key_path))
app = Spaceship::ConnectAPI::App.find(bundle_id) or abort("no app for #{bundle_id}")
notes = File.read(notes_file, encoding: "UTF-8").strip

build = nil
# Processing usually takes 5–20 minutes; give it up to 40.
80.times do |i|
  build = Spaceship::ConnectAPI::Build.all(app_id: app.id, version: build_number).first
  state = build&.processing_state
  puts "build #{build_number}: #{state || "not visible yet"}" if i % 4 == 0
  break if state == "VALID"
  abort("build #{build_number} processing #{state}") if %w[FAILED INVALID].include?(state)
  sleep 30
end
abort("build #{build_number} still processing; set notes later") unless build&.processing_state == "VALID"

loc = build.get_beta_build_localizations.find { |l| l.locale == "en-US" }
if loc
  loc.update(attributes: { whatsNew: notes })
else
  Spaceship::ConnectAPI.post_beta_build_localizations(build_id: build.id, attributes: { locale: "en-US", whatsNew: notes })
end
puts "TestFlight notes set for build #{build_number}"
