# Builds a local HTML mockup of the en-US App Store page from the same files the listing
# push uploads, so you can see the order, copy and screenshots before publishing.
#
#   ruby store_preview.rb <metadataDir> <outDir> [iconPath]
#
# Reads <metadataDir>/texts/en-US/*.txt and <metadataDir>/screenshots/en-US/*.png
# (sorted by filename, the same order the push uses). Writes <outDir>/index.html, copies
# the screenshots and icon next to it, and prints the page's file list. This is a mockup,
# not Apple's layout.
require "fileutils"
require "cgi"

metadata, out, icon = ARGV
abort("usage: store_preview.rb <metadataDir> <outDir> [iconPath]") unless out

texts = File.join(metadata, "texts", "en-US")
shots_src = File.join(metadata, "screenshots", "en-US")
FileUtils.mkdir_p(File.join(out, "screenshots"))

def text(dir, name)
  path = File.join(dir, "#{name}.txt")
  File.exist?(path) ? File.read(path, encoding: "UTF-8").strip : ""
end

# On a case-insensitive disk "*.{png,PNG}" matches each file twice; uniq keeps one of each.
shots = Dir[File.join(shots_src, "*.{png,PNG}")].uniq(&:downcase).sort
abort("no screenshots in #{shots_src}") if shots.empty?
shots.each { |s| FileUtils.cp(s, File.join(out, "screenshots", File.basename(s))) }

icon_html = ""
if icon && File.exist?(icon)
  FileUtils.cp(icon, File.join(out, "icon.png"))
  icon_html = %(<img class="icon" src="icon.png" alt="">)
end

esc = ->(s) { CGI.escapeHTML(s.to_s) }
name = text(texts, "name")
subtitle = text(texts, "subtitle")
promo = text(texts, "promotional_text")
description = text(texts, "description")
support = text(texts, "support_url")
privacy = text(texts, "privacy_url")

shot_tags = shots.map do |s|
  file = File.basename(s)
  %(<figure><img src="screenshots/#{esc.(file)}" alt="#{esc.(file)}"><figcaption>#{esc.(file)}</figcaption></figure>)
end.join("\n")

desc_html = description.split(/\n{2,}/).map { |para| "<p>#{esc.(para).gsub("\n", "<br>")}</p>" }.join("\n")

html = <<~HTML
  <!doctype html>
  <html lang="en"><head><meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Store page mockup: #{esc.(name)}</title>
  <style>
    :root { --bg:#fff; --fg:#1d1d1f; --muted:#6e6e73; --line:#d2d2d7; --blue:#0071e3; }
    @media (prefers-color-scheme: dark) { :root { --bg:#000; --fg:#f5f5f7; --muted:#a1a1a6; --line:#3a3a3c; } }
    body { margin:0; background:var(--bg); color:var(--fg); font:16px/1.45 -apple-system, system-ui, sans-serif; }
    .banner { background:#fff4d6; color:#5b4a00; padding:10px 16px; font-size:14px; text-align:center; }
    main { max-width:980px; margin:0 auto; padding:24px 16px 64px; }
    header { display:flex; gap:20px; align-items:center; }
    .icon { width:120px; height:120px; border-radius:26px; box-shadow:0 2px 8px rgba(0,0,0,.2); }
    h1 { font-size:28px; margin:0; } .sub { color:var(--muted); margin:4px 0 12px; font-size:17px; }
    .get { display:inline-block; background:var(--blue); color:#fff; border-radius:999px; padding:6px 22px; font-weight:600; }
    .shots { display:flex; gap:14px; overflow-x:auto; padding:24px 0 12px; scroll-snap-type:x mandatory; }
    .shots figure { margin:0; flex:0 0 auto; scroll-snap-align:start; }
    .shots img { height:520px; border-radius:22px; border:1px solid var(--line); }
    .shots figcaption { font-size:12px; color:var(--muted); margin-top:6px; text-align:center; }
    h2 { font-size:21px; border-top:1px solid var(--line); padding-top:20px; margin-top:28px; }
    .promo { font-style:italic; color:var(--muted); }
    .desc p { margin:0 0 12px; }
    footer { margin-top:32px; font-size:14px; color:var(--muted); }
    footer a { color:var(--blue); }
    @media (max-width:600px) { .shots img { height:420px; } .icon { width:88px; height:88px; } }
  </style></head>
  <body>
  <div class="banner">Mockup generated from the files the listing push uploads. Not Apple's exact layout.</div>
  <main>
    <header>
      #{icon_html}
      <div>
        <h1>#{esc.(name)}</h1>
        <div class="sub">#{esc.(subtitle)}</div>
        <span class="get">Get</span>
      </div>
    </header>
    <div class="shots">
  #{shot_tags}
    </div>
    <h2>Promotional text</h2>
    <p class="promo">#{esc.(promo)}</p>
    <h2>Description</h2>
    <div class="desc">#{desc_html}</div>
    <footer>
      #{support.empty? ? "" : %(Support: <a href="#{esc.(support)}">#{esc.(support)}</a><br>)}
      #{privacy.empty? ? "" : %(Privacy Policy: <a href="#{esc.(privacy)}">#{esc.(privacy)}</a>)}
    </footer>
  </main>
  </body></html>
HTML

File.write(File.join(out, "index.html"), html)
puts "wrote #{File.join(out, "index.html")}"
puts "#{shots.size} screenshots: #{shots.map { |s| File.basename(s) }.join(", ")}"
