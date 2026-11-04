# In-app purchases in App Store Connect, and their App Review screenshots.
#
#   bundle exec ruby appstore_iap.rb list   <bundleId> <keyId> <issuerId> <keyPath>
#   bundle exec ruby appstore_iap.rb upload <bundleId> <keyId> <issuerId> <keyPath> <dir>
#
# `list` is read-only: one JSON object on stdout with every in-app purchase, its
# state, and whether App Review has its screenshot.
#
# `upload` sends the review screenshot from <dir> to each in-app purchase:
# <dir>/<productId>.png when that exists, else <dir>/review_screenshot.png for
# all of them. Apple asks for one per purchase "that clearly shows the item
# being offered" — for an app with one purchase screen, the same image serves
# every pack. A purchase whose screenshot already matches (same MD5) is skipped;
# a different one is replaced.
#
# spaceship has no in-app purchase API, so this calls App Store Connect's REST
# API directly with spaceship's token.
require "spaceship"
require "json"
require "net/http"
require "digest"

mode, bundle_id, key_id, issuer_id, key_path, dir = ARGV
abort("usage: appstore_iap.rb list|upload <bundleId> <keyId> <issuerId> <keyPath> [dir]") unless key_path
abort("upload needs the screenshot folder") if mode == "upload" && dir.nil?

API = "https://api.appstoreconnect.apple.com"
TOKEN = Spaceship::ConnectAPI::Token.create(key_id: key_id, issuer_id: issuer_id, filepath: File.expand_path(key_path))

def request(method, path, body = nil)
  uri = URI(path.start_with?("http") ? path : API + path)
  req = Net::HTTP.const_get(method.capitalize).new(uri)
  req["Authorization"] = "Bearer #{TOKEN.text}"
  req["Content-Type"] = "application/json"
  req.body = JSON.generate(body) if body
  res = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |h| h.request(req) }
  raise "#{method.upcase} #{uri.path}: #{res.code} #{res.body.to_s[0, 300]}" unless res.code.start_with?("2")
  res.body.to_s.empty? ? {} : JSON.parse(res.body)
end

def app_id(bundle_id)
  found = request(:get, "/v1/apps?filter[bundleId]=#{bundle_id}&limit=1")["data"].first
  found && found["id"]
end

def purchases(app)
  request(:get, "/v1/apps/#{app}/inAppPurchasesV2?limit=200")["data"].map do |p|
    shot = (request(:get, "/v2/inAppPurchases/#{p['id']}/appStoreReviewScreenshot")["data"] rescue nil)
    a = shot && shot["attributes"]
    { "id" => p["id"], "productId" => p.dig("attributes", "productId"), "name" => p.dig("attributes", "name"),
      "type" => p.dig("attributes", "inAppPurchaseType"), "state" => p.dig("attributes", "state"),
      "screenshot" => a && { "id" => shot["id"], "fileName" => a["fileName"],
                             "md5" => a["sourceFileChecksum"],
                             "state" => a.dig("assetDeliveryState", "state") } }
  end
end

def upload(purchase, path)
  bytes = File.binread(path)
  md5 = Digest::MD5.hexdigest(bytes)
  old = purchase["screenshot"]
  return "#{purchase['productId']}: already up to date" if old && old["md5"] == md5
  request(:delete, "/v1/inAppPurchaseAppStoreReviewScreenshots/#{old['id']}") if old
  created = request(:post, "/v1/inAppPurchaseAppStoreReviewScreenshots", { "data" => {
    "type" => "inAppPurchaseAppStoreReviewScreenshots",
    "attributes" => { "fileName" => File.basename(path), "fileSize" => bytes.bytesize },
    "relationships" => { "inAppPurchaseV2" => { "data" => { "type" => "inAppPurchases", "id" => purchase["id"] } } },
  } })["data"]
  created.dig("attributes", "uploadOperations").each do |op|
    uri = URI(op["url"])
    req = Net::HTTP.const_get(op["method"].capitalize).new(uri)
    op["requestHeaders"].each { |h| req[h["name"]] = h["value"] }
    req.body = bytes.byteslice(op["offset"], op["length"])
    res = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |h| h.request(req) }
    raise "upload part: #{res.code}" unless res.code.start_with?("2")
  end
  request(:patch, "/v1/inAppPurchaseAppStoreReviewScreenshots/#{created['id']}", { "data" => {
    "type" => "inAppPurchaseAppStoreReviewScreenshots", "id" => created["id"],
    "attributes" => { "uploaded" => true, "sourceFileChecksum" => md5 },
  } })
  "#{purchase['productId']}: #{old ? 'replaced' : 'uploaded'} #{File.basename(path)}"
end

begin
  app = app_id(bundle_id) or raise "No app with bundle id #{bundle_id} in App Store Connect"
  case mode
  when "list"
    puts JSON.generate({ "bundleId" => bundle_id, "purchases" => purchases(app), "fetchedAt" => Time.now.utc.iso8601 })
  when "upload"
    all = purchases(app)
    puts "No in-app purchases in App Store Connect." if all.empty?
    all.each do |p|
      path = [File.join(dir, "#{p['productId']}.png"), File.join(dir, "review_screenshot.png")].find { |f| File.exist?(f) }
      puts(path ? upload(p, path) : "#{p['productId']}: no screenshot in #{dir}")
    end
  else
    abort("unknown mode #{mode}")
  end
rescue => e
  if mode == "list"
    puts JSON.generate({ "bundleId" => bundle_id, "error" => "#{e.class}: #{e.message}"[0, 400] })
  else
    abort("#{e.class}: #{e.message}")
  end
end
