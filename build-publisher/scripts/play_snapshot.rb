# Read-only snapshot of an app on Google Play: tracks, en-US listing text and listing
# images. Prints one JSON object on stdout; downloads image thumbnails into <outDir>.
#
#   bundle exec ruby play_snapshot.rb <packageName> <serviceAccountKey> <outDir>
#
# It opens an edit to read through and always deletes it — nothing is ever committed,
# so this can run on every window focus without touching what is on Play. Leaving the
# edit open would make the next real upload fail with "This edit has expired".
require "googleauth"
require "net/http"
require "json"
require "fileutils"

pkg, key, out = ARGV
abort("usage: play_snapshot.rb <package> <key> <outDir>") unless pkg && key && out
FileUtils.mkdir_p(out)

auth = Google::Auth::ServiceAccountCredentials.make_creds(
  json_key_io: File.open(key), scope: "https://www.googleapis.com/auth/androidpublisher")
HDR = { "Authorization" => "Bearer #{auth.fetch_access_token!["access_token"]}" }
BASE = "https://androidpublisher.googleapis.com/androidpublisher/v3/applications/#{pkg}"
API = Net::HTTP.new("androidpublisher.googleapis.com", 443).tap { |h| h.use_ssl = true; h.start }

def get(path)
  r = API.request(Net::HTTP::Get.new(URI("#{BASE}#{path}"), HDR))
  r.is_a?(Net::HTTPSuccess) ? JSON.parse(r.body) : nil
end

r = API.request(Net::HTTP::Post.new(URI("#{BASE}/edits"), HDR))
edit = JSON.parse(r.body)["id"] rescue nil
unless edit
  puts JSON.generate({ "error" => "Play refused to open an edit (#{r.code}): #{r.body.to_s[0, 300]}" })
  exit 0
end

result = { "package" => pkg, "fetchedAt" => Time.now.utc.iso8601 }
begin
  result["tracks"] = (get("/edits/#{edit}/tracks") || {})["tracks"] || []
  listing = get("/edits/#{edit}/listings/en-US")
  result["listing"] = listing && listing.slice("title", "shortDescription", "fullDescription")
  result["images"] = {}
  %w[icon featureGraphic phoneScreenshots].each do |type|
    imgs = (get("/edits/#{edit}/listings/en-US/#{type}") || {})["images"] || []
    result["images"][type] = imgs.each_with_index.map do |img, i|
      path = File.join(out, "#{type}_#{i + 1}.png")
      File.binwrite(path, Net::HTTP.get(URI(img["url"]))) rescue path = nil
      { "sha256" => img["sha256"], "path" => path }
    end
  end
ensure
  API.request(Net::HTTP::Delete.new(URI("#{BASE}/edits/#{edit}"), HDR)) rescue nil
end
puts JSON.generate(result)
