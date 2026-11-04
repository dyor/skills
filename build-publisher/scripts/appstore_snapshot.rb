# Read-only snapshot of an app in App Store Connect: TestFlight builds, App Store
# versions and their review state. Prints one JSON object on stdout.
#
#   bundle exec ruby appstore_snapshot.rb <bundleId> <keyId> <issuerId> <keyPath>
#
# Unlike Google Play, App Store Connect reports review status directly
# (WAITING_FOR_REVIEW, IN_REVIEW, REJECTED, READY_FOR_SALE …), so "What's next" can say
# exactly where a submission is. Nothing here writes to App Store Connect.
require "spaceship"
require "json"

bundle_id, key_id, issuer_id, key_path = ARGV
abort("usage: appstore_snapshot.rb <bundleId> <keyId> <issuerId> <keyPath>") unless key_path

def out(h) = puts(JSON.generate(h))

begin
  Spaceship::ConnectAPI.auth(key_id: key_id, issuer_id: issuer_id, filepath: key_path)
  app = Spaceship::ConnectAPI::App.find(bundle_id)
  unless app
    out({ "bundleId" => bundle_id, "exists" => false, "fetchedAt" => Time.now.utc.iso8601 })
    exit 0
  end

  builds = Spaceship::ConnectAPI::Build.all(app_id: app.id, sort: "-uploadedDate", limit: 10).map do |b|
    { "buildNumber" => b.version, "version" => (b.app_version rescue nil),
      "processingState" => b.processing_state, "uploadedDate" => b.uploaded_date,
      "expired" => b.expired }
  end

  versions = app.get_app_store_versions(filter: { platform: "IOS" }, includes: "build").first(5).map do |v|
    { "version" => v.version_string, "state" => v.app_store_state,
      "build" => (v.build&.version rescue nil), "createdDate" => v.created_date }
  end

  info = app.fetch_edit_app_info || app.fetch_live_app_info
  out({ "bundleId" => bundle_id, "exists" => true, "appId" => app.id, "name" => app.name,
        "sku" => app.sku, "builds" => builds, "versions" => versions,
        "fetchedAt" => Time.now.utc.iso8601 })
rescue => e
  out({ "bundleId" => bundle_id, "error" => "#{e.class}: #{e.message}"[0, 400] })
end
