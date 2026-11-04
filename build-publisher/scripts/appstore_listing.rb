# The App Store listing (en-US): read it, pull it into local files, or push local files.
#
#   bundle exec ruby appstore_listing.rb snapshot <bundleId> <keyId> <issuerId> <keyPath> <cacheDir>
#   bundle exec ruby appstore_listing.rb pull     <bundleId> <keyId> <issuerId> <keyPath> <metadataDir>
#   bundle exec ruby appstore_listing.rb push     <bundleId> <keyId> <issuerId> <keyPath> <metadataDir>
#
# <metadataDir> uses the layout fastlane deliver reads, so either tool can use it:
#   texts/en-US/{name,subtitle,description,keywords,promotional_text,release_notes,
#                support_url,marketing_url,privacy_url}.txt
#   screenshots/en-US/*.png   (device size inferred from pixel dimensions; order = filename order)
#
# snapshot and pull only read App Store Connect. push writes to the version being prepared
# (never a live one) and replaces a device size's screenshots only when they differ.
require "spaceship"
require "json"
require "digest"
require "fileutils"
require "net/http"

mode, bundle_id, key_id, issuer_id, key_path, dir = ARGV
abort("usage: appstore_listing.rb snapshot|pull|push <bundleId> <keyId> <issuerId> <keyPath> <dir>") unless dir
LOCALE = "en-US"

# Text files ↔ App Store Connect fields. [file, object, attribute, API attribute, limit]
FIELDS = [
  ["name",             :info,    :name,             "name",            30],
  ["subtitle",         :info,    :subtitle,         "subtitle",        30],
  ["privacy_url",      :info,    :privacy_policy_url, "privacyPolicyUrl", nil],
  ["description",      :version, :description,      "description",     4000],
  ["keywords",         :version, :keywords,         "keywords",        100],
  ["promotional_text", :version, :promotional_text, "promotionalText", 170],
  ["release_notes",    :version, :whats_new,        "whatsNew",        4000],
  ["support_url",      :version, :support_url,      "supportUrl",      nil],
  ["marketing_url",    :version, :marketing_url,    "marketingUrl",    nil],
].freeze

# Pixel size → App Store Connect display type (portrait; landscape is the same swapped).
DISPLAY_TYPES = {
  [1320, 2868] => "APP_IPHONE_67", [1290, 2796] => "APP_IPHONE_67", [1260, 2736] => "APP_IPHONE_67",
  [1242, 2688] => "APP_IPHONE_65", [1284, 2778] => "APP_IPHONE_65",
  [1179, 2556] => "APP_IPHONE_61", [1206, 2622] => "APP_IPHONE_61",
  [1170, 2532] => "APP_IPHONE_58", [1125, 2436] => "APP_IPHONE_58", [1080, 2340] => "APP_IPHONE_58",
  [1242, 2208] => "APP_IPHONE_55",
  [2064, 2752] => "APP_IPAD_PRO_3GEN_129", [2048, 2732] => "APP_IPAD_PRO_3GEN_129",
}.freeze

def out(h) = puts(JSON.generate(h))

def png_size(path)
  data = File.binread(path, 24)
  return nil unless data && data[0, 8] == "\x89PNG\r\n\x1A\n".b
  data[16, 8].unpack("NN")
end

def display_type(path)
  w, h = png_size(path) || (return nil)
  DISPLAY_TYPES[[w, h]] || DISPLAY_TYPES[[h, w]]
end

def local_screenshots(dir)
  # On a case-insensitive disk "*.{png,PNG}" matches each file twice; uniq keeps one of each.
  Dir[File.join(dir, "screenshots", LOCALE, "*.{png,PNG}")].uniq(&:downcase).sort
    .group_by { |p| display_type(p) || "UNKNOWN" }
end

Spaceship::ConnectAPI.auth(key_id: key_id, issuer_id: issuer_id, filepath: key_path)
app = Spaceship::ConnectAPI::App.find(bundle_id) or (out({ "error" => "No app for #{bundle_id} in App Store Connect" }); exit 0)
platform = Spaceship::ConnectAPI::Platform::IOS

# The version being prepared if there is one (editable), else the live one (read-only).
edit_version = app.get_edit_app_store_version(platform: platform)
version = edit_version || app.get_live_app_store_version(platform: platform)
info = app.fetch_edit_app_info || app.fetch_live_app_info
info_loc = info&.get_app_info_localizations&.find { |l| l.locale == LOCALE }
ver_loc = version&.get_app_store_version_localizations&.find { |l| l.locale == LOCALE }
sets = ver_loc ? ver_loc.get_app_screenshot_sets : []

def value_of(field, info_loc, ver_loc)
  _, obj, attr = field
  src = obj == :info ? info_loc : ver_loc
  src&.send(attr)
end

# Makes a screenshot set match `paths` exactly: same images, same order, no copies.
#
# Spaceship retries a POST that timed out, and the first try often succeeded anyway, so a
# screenshot can land twice. So this never trusts one create call: it re-reads the set
# every step, keeps the leading run that matches the files in order, deletes every other
# copy, and creates only the next file that is missing. Deletes are asynchronous, so it
# waits for them to clear before creating more; the set holds at most 10 screenshots.
def sync_screenshot_set(set_id, paths)
  wanted = paths.map { |p| Digest::MD5.file(p).hexdigest }
  120.times do
    current = Spaceship::ConnectAPI::AppScreenshotSet.get(app_screenshot_set_id: set_id).app_screenshots.to_a
    matched = 0
    extra = []
    current.each do |s|
      if matched < wanted.size && s.source_file_checksum == wanted[matched]
        matched += 1
      else
        extra << s
      end
    end
    if extra.any?
      extra.each { |s| s.delete! rescue nil }
      sleep 3
      next
    end
    return if matched == wanted.size
    if current.size >= 10
      sleep 3
      next
    end
    begin
      Spaceship::ConnectAPI::AppScreenshot.create(app_screenshot_set_id: set_id, path: paths[matched], wait_for_processing: false)
      puts "  created #{File.basename(paths[matched])} (#{matched + 1} of #{wanted.size})"
    rescue StandardError => e
      puts "  create of #{File.basename(paths[matched])} failed, checking the set again: #{e.message[0, 120]}"
    end
    sleep 2
  end
  abort("screenshot set #{set_id} did not reach #{wanted.size} matching screenshots; check App Store Connect")
end

case mode
when "snapshot"
  FileUtils.mkdir_p(dir)
  shots = sets.to_h do |set|
    list = (set.app_screenshots || []).each_with_index.map do |s, i|
      path = File.join(dir, "#{set.screenshot_display_type}_#{i + 1}.png")
      url = s.image_asset_url(width: 300, type: "png") rescue nil
      begin
        File.binwrite(path, Net::HTTP.get(URI(url))) if url
      rescue StandardError
        path = nil
      end
      { "md5" => s.source_file_checksum, "fileName" => s.file_name, "path" => (url ? path : nil) }
    end
    [set.screenshot_display_type, list]
  end
  out({
    "fetchedAt" => Time.now.utc.iso8601,
    "version" => version&.version_string, "state" => version&.app_store_state,
    "editable" => !edit_version.nil?,
    "fields" => FIELDS.to_h { |f| [f[0], value_of(f, info_loc, ver_loc)] },
    "screenshots" => shots,
  })

when "pull"
  texts = File.join(dir, "texts", LOCALE)
  FileUtils.mkdir_p(texts)
  FIELDS.each do |f|
    v = value_of(f, info_loc, ver_loc)
    File.write(File.join(texts, "#{f[0]}.txt"), v.to_s) unless v.to_s.empty?
  end
  shots_dir = File.join(dir, "screenshots", LOCALE)
  FileUtils.mkdir_p(shots_dir)
  n = 0
  sets.each do |set|
    (set.app_screenshots || []).each do |s|
      url = s.image_asset_url(type: "png") or next
      n += 1
      File.binwrite(File.join(shots_dir, format("%02d_%s.png", n, set.screenshot_display_type)), Net::HTTP.get(URI(url)))
    end
  end
  puts "pulled #{FIELDS.count { |f| !value_of(f, info_loc, ver_loc).to_s.empty? }} text fields and #{n} screenshots into #{dir}"

when "push"
  abort("No App Store version is being prepared — nothing editable. Create a new version in App Store Connect first.") unless edit_version && ver_loc
  texts = File.join(dir, "texts", LOCALE)
  problems = []
  updates = { info: {}, version: {} }
  FIELDS.each do |file, obj, attr, api, limit|
    path = File.join(texts, "#{file}.txt")
    next unless File.exist?(path)
    v = File.read(path, encoding: "UTF-8").strip
    problems << "#{file}.txt is #{v.length} characters; the limit is #{limit}" if limit && v.length > limit
    current = (obj == :info ? info_loc : ver_loc)&.send(attr).to_s.strip
    updates[obj][api] = v unless v == current
  end
  abort("Not uploading:\n  " + problems.join("\n  ")) unless problems.empty?

  if updates[:info].any?
    abort("App info (name/subtitle/privacy URL) isn't editable right now") unless info_loc
    info_loc.update(attributes: updates[:info])
    puts "updated app info: #{updates[:info].keys.join(', ')}"
  end
  if updates[:version].any?
    ver_loc.update(attributes: updates[:version])
    puts "updated version #{edit_version.version_string}: #{updates[:version].keys.join(', ')}"
  end

  local_screenshots(dir).each do |type, paths|
    if type == "UNKNOWN"
      abort("Unrecognised screenshot size: #{paths.map { |p| "#{File.basename(p)} #{png_size(p)&.join('×')}" }.join(', ')}")
    end
    set = sets.find { |s| s.screenshot_display_type == type } ||
          ver_loc.create_app_screenshot_set(attributes: { screenshotDisplayType: type })
    live = (set.app_screenshots || []).map(&:source_file_checksum)
    wanted = paths.map { |p| Digest::MD5.file(p).hexdigest }
    next puts("#{type}: unchanged") if live == wanted
    sync_screenshot_set(set.id, paths)
    puts "#{type}: set to #{paths.size} screenshot#{paths.size == 1 ? '' : 's'}, in order"
  end
  # Refresh the local store-page mockup from the same files that were just uploaded.
  # STORE_ICON (optional) is the 1024 icon to show on it.
  preview_dir = File.join(dir, "preview")
  preview_script = File.join(__dir__, "store_preview.rb")
  icon = ENV["STORE_ICON"]
  args = ["ruby", preview_script, dir, preview_dir]
  args << icon if icon && !icon.empty?
  puts(system(*args) ? "store page mockup: #{File.join(preview_dir, 'index.html')}" : "store page mockup failed (listing is still uploaded)")
  puts "App Store listing uploaded (en-US) — it goes out with the next Submit for review"
else
  abort("unknown mode #{mode}")
end
