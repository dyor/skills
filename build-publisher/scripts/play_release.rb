#!/usr/bin/env ruby
# Uploads an AAB and sets the release on every non-production track that already holds one,
# plus the target track, ALL IN ONE Play edit.
#
# Why one edit: Play validates the declarations (advertising ID, permissions, ...) of every
# release in the edit it commits, and the error never says which track is at fault. An old
# build left on a track nobody uses anymore therefore blocks every new upload. Keeping each
# track that holds a release on the same, newest build means no stale build can fail a
# future requirement. Production is never touched here (promotions handle it).
#
# Env: KEY (service account json), PKG, AAB, NOTES_FILE, TRACK (target), VERSION_NAME,
#      SKIP_UPLOAD=1 (reuse a code already on Play; needs VERSION_CODE), VALIDATE_ONLY=1.
require "googleauth"; require "net/http"; require "json"; require "uri"

key, pkg, aab, track = ENV.fetch("KEY"), ENV.fetch("PKG"), ENV["AAB"], ENV.fetch("TRACK")
notes = File.exist?(ENV["NOTES_FILE"].to_s) ? File.read(ENV["NOTES_FILE"], encoding: "UTF-8").strip : ""
abort("release notes are over Play's 500-character limit") if notes.encode("UTF-16LE").bytesize / 2 > 500

auth = Google::Auth::ServiceAccountCredentials.make_creds(
  json_key_io: File.open(key), scope: "https://www.googleapis.com/auth/androidpublisher")
tok = auth.fetch_access_token!["access_token"]
base = "https://androidpublisher.googleapis.com/androidpublisher/v3/applications/#{pkg}"

def conn(uri)
  h = Net::HTTP.new(uri.host, 443); h.use_ssl = true; h.read_timeout = 900; h.open_timeout = 60; h
end

def call(verb, url, tok, body = nil)
  uri = URI(url)
  req = Net::HTTP.const_get(verb).new(uri.request_uri, "Authorization" => "Bearer #{tok}", "Content-Type" => "application/json")
  req.body = body.to_json if body
  r = conn(uri).request(req)
  [r.code.to_i, (JSON.parse(r.body) rescue r.body)]
end

_, edit = call("Post", "#{base}/edits", tok, {})
id = edit["id"] or abort("could not open a Play edit: #{edit}")
done = false
at_exit { call("Delete", "#{base}/edits/#{id}", tok) unless done }

code = ENV["VERSION_CODE"].to_s
if ENV["SKIP_UPLOAD"] != "1"
  puts "uploading #{aab} …"
  uri = URI("https://androidpublisher.googleapis.com/upload/androidpublisher/v3/applications/#{pkg}/edits/#{id}/bundles?uploadType=media")
  req = Net::HTTP::Post.new(uri.request_uri, "Authorization" => "Bearer #{tok}", "Content-Type" => "application/octet-stream")
  req.body = File.binread(aab)
  r = conn(uri).request(req)
  abort("upload failed (#{r.code}): #{r.body}") unless r.code == "200"
  code = JSON.parse(r.body)["versionCode"].to_s
end
abort("no version code") if code.empty?

# Every non-production track that already holds a release stays on the newest build.
existing = {}
%w[internal alpha beta].each do |t|
  c, b = call("Get", "#{base}/edits/#{id}/tracks/#{t}", tok)
  existing[t] = c == 200 ? (b["releases"] || []) : []
end
targets = ([track] + existing.select { |_, r| !r.empty? }.keys).uniq - ["production"]

targets.each do |t|
  was_draft = t != track && existing[t].any? { |r| r["status"] == "draft" } && existing[t].none? { |r| r["status"] == "completed" }
  release = {"name" => ENV["VERSION_NAME"].to_s.empty? ? nil : ENV["VERSION_NAME"], "versionCodes" => [code],
             "status" => was_draft ? "draft" : "completed"}.compact
  release["releaseNotes"] = [{"language" => "en-US", "text" => notes}] unless notes.empty?
  c, b = call("Put", "#{base}/edits/#{id}/tracks/#{t}", tok, {"track" => t, "releases" => [release]})
  abort("#{t} track update failed (#{c}): #{b.to_json}") unless c == 200
  puts "#{t}: versionCode #{code} (#{release["status"]})"
end

if ENV["VALIDATE_ONLY"] == "1"
  c, b = call("Post", "#{base}/edits/#{id}:validate", tok)
  puts "validate: #{c} #{b.to_json}"
  exit(c == 200 ? 0 : 1)
end

# A draft app wants changesNotSentForReview=true; an app whose changes are sent automatically
# rejects it. Try with, and retry without when Play says it must not be set.
c, b = call("Post", "#{base}/edits/#{id}:commit?changesNotSentForReview=true", tok)
if c == 400 && b.to_json.include?("must not be set")
  puts "Play sends these changes for review automatically."
  c, b = call("Post", "#{base}/edits/#{id}:commit", tok)
end
abort("commit failed (#{c}): #{b.to_json}") unless c == 200
done = true
puts "uploaded versionCode #{code} to #{targets.join(", ")}"
