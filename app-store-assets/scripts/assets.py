#!/usr/bin/env python3
"""
App store assets: screenshots for the App Store, Google Play and the app's website,
from one set of raw phone screenshots and one shot list.

Everything app-specific (paths, shots, captions, colours, website) lives in the app's
own config file, a Markdown file with one ```json block (see templates/assets.md).
This script is the generic part and contains no app's details.

    python3 assets.py checklist   # make today's capture folder + SHOTLIST.md
    python3 assets.py verify      # which raw shot each screenshot will use
    python3 assets.py compose     # captioned store screenshots, every size in "outputs"
    python3 assets.py web         # website images; prints the screenshot list as JSON
    python3 assets.py text        # store listing text lengths against the store limits

Options: --config PATH (default: distribution/assets.md, relative to --root),
--root PATH (the app repo; default: current directory).

Requires Pillow (pip install Pillow).
"""
import argparse
import datetime as dt
import json
import re
import sys
from pathlib import Path

try:
    from PIL import Image, ImageDraw, ImageFilter, ImageFont
except ImportError:
    sys.exit("Pillow is required: pip install Pillow")

RAW_EXTS = (".png", ".jpg", ".jpeg")
DATED = re.compile(r"^\d{4}-\d{2}-\d{2}$")

# Store character limits, by file name in the text folders.
LIMITS = {
    "ios": {"name.txt": 30, "subtitle.txt": 30, "promotional_text.txt": 170,
            "keywords.txt": 100, "description.txt": 4000},
    "play": {"title.txt": 30, "short_description.txt": 80, "full_description.txt": 4000},
}

DEFAULT_STYLE = {
    "background": "#1F6B35",
    "headline": "#FFFFFF",
    "accent": "#FFCC33",
    "subline": "#DEEEE2",
    "font": "/System/Library/Fonts/Avenir Next.ttc",
    "headline_font_index": 0,
    "subline_font_index": 5,
    # Cropped from the top of every raw shot: the phone's status bar dates the shot.
    "status_bar_px": 150,
}


# ---------------------------------------------------------------------------
# Config


def load_config(root: Path, path: Path) -> dict:
    """Reads the first ```json block of the app's assets.md."""
    text = path.read_text(encoding="utf-8")
    m = re.search(r"```json\s*\n(.*?)\n```", text, re.S)
    if not m:
        sys.exit(f"No ```json block in {path}")
    try:
        cfg = json.loads(m.group(1))
    except json.JSONDecodeError as e:
        sys.exit(f"{path}: invalid JSON in the config block: {e}")
    cfg["style"] = {**DEFAULT_STYLE, **cfg.get("style", {})}
    cfg["_root"] = root
    if not cfg.get("shots"):
        sys.exit(f"{path}: no shots")
    return cfg


def rel(cfg, p) -> Path:
    """Paths in the config are relative to the app repo; ~ is expanded."""
    p = Path(str(p)).expanduser()
    return p if p.is_absolute() else cfg["_root"] / p


def rgb(hex_colour: str):
    h = hex_colour.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def media_dirs(cfg):
    """Capture folders, newest first (YYYY-MM-DD names sort by date)."""
    media = rel(cfg, cfg.get("media_dir", "distribution/media"))
    if not media.is_dir():
        return []
    return sorted((d for d in media.iterdir() if d.is_dir() and DATED.match(d.name)), reverse=True)


def resolve(cfg, shot):
    """The raw file for a shot: the newest capture folder holding <id>.<ext>, else the
    newest holding its legacy "file" name. Re-shooting one screen only needs that one."""
    names = [shot["id"] + ext for ext in RAW_EXTS]
    for d in media_dirs(cfg):
        for n in names:
            if (d / n).exists():
                return d / n
    if shot.get("file"):
        for d in media_dirs(cfg):
            if (d / shot["file"]).exists():
                return d / shot["file"]
    return None


def plain(text: str) -> str:
    return text.replace("*", "")


# ---------------------------------------------------------------------------
# Rendering (layout designed at 1290 wide and scaled to each output size)


def _accent_words(text):
    inside = False
    for word in text.split():
        starts, ends = word.startswith("*"), word.endswith("*")
        yield word.strip("*"), inside or starts
        if starts and not ends:
            inside = True
        if ends:
            inside = False


def draw_headline(draw, text, y, width, size, style):
    """Centred headline, *starred* words in the accent colour; two balanced lines if too wide."""
    font = ImageFont.truetype(style["font"], size, index=style["headline_font_index"])
    words = list(_accent_words(text))
    measure = lambda ws: draw.textlength(" ".join(w for w, _ in ws), font=font)
    lines = [words]
    if measure(words) > width * 0.86 and len(words) > 1:
        cut = min(range(1, len(words)), key=lambda i: max(measure(words[:i]), measure(words[i:])))
        lines = [words[:cut], words[cut:]]
    for line in lines:
        x = (width - measure(line)) / 2
        for i, (word, accent) in enumerate(line):
            piece = word + (" " if i < len(line) - 1 else "")
            draw.text((x, y), piece, font=font, fill=rgb(style["accent" if accent else "headline"]))
            x += draw.textlength(piece, font=font)
        y += int(size * 1.18)
    return y


def rounded(img, radius):
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, *img.size), radius, fill=255)
    out = Image.new("RGBA", img.size)
    out.paste(img, (0, 0), mask)
    return out


def prepared(cfg, shot):
    """The raw screen with blurs applied and the status bar cropped."""
    src = resolve(cfg, shot)
    if src is None:
        sys.exit(f"No raw screenshot for '{shot['id']}'. Run `verify`.")
    img = Image.open(src).convert("RGB")
    for box in shot.get("blur", []):
        box = tuple(box)
        img.paste(img.crop(box).filter(ImageFilter.GaussianBlur(14)), box)
    return img.crop((0, cfg["style"]["status_bar_px"], img.width, img.height))


def compose(cfg, shot, size):
    style = cfg["style"]
    width, _ = size
    screen = prepared(cfg, shot)

    canvas = Image.new("RGB", size, rgb(style["background"]))
    draw = ImageDraw.Draw(canvas)
    scale = width / 1290
    y = draw_headline(draw, shot["headline"], int(150 * scale), width, int(96 * scale), style)
    sub = ImageFont.truetype(style["font"], int(54 * scale), index=style["subline_font_index"])
    draw.text(((width - draw.textlength(shot["subline"], font=sub)) / 2, y + int(20 * scale)),
              shot["subline"], font=sub, fill=rgb(style["subline"]))
    top = y + int(150 * scale)

    # The screen fills the rest, centred, with a soft shadow.
    shot_w = int(width * 0.84)
    screen = screen.resize((shot_w, int(screen.height * shot_w / screen.width)), Image.LANCZOS)
    screen = rounded(screen, int(56 * scale))
    x = (width - shot_w) // 2
    shadow = Image.new("RGBA", size, (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle(
        (x, top + 18, x + shot_w, top + screen.height + 18), int(56 * scale), fill=(0, 0, 0, 110))
    soft = shadow.filter(ImageFilter.GaussianBlur(24))
    canvas.paste(soft, (0, 0), soft)
    canvas.paste(screen, (x, top), screen)
    return canvas


def out_name(pattern, n, shot, src):
    return pattern.format(n=n, id=shot["id"], stem=src.stem)


# ---------------------------------------------------------------------------
# Commands


def cmd_checklist(cfg, args):
    media = rel(cfg, cfg.get("media_dir", "distribution/media"))
    folder = media / dt.date.today().isoformat()
    folder.mkdir(parents=True, exist_ok=True)
    lines = [
        f"# Screenshots to capture: {cfg.get('app', 'app')}",
        "",
        f"Save each screenshot in this folder as `<id>.png` (or .jpg). Re-shoot only the",
        "screens that changed; the rest keep using their newest earlier capture.",
        "",
        "| # | id (file name) | Screen to show | Currently using |",
        "|---|---|---|---|",
    ]
    for n, shot in enumerate(cfg["shots"], start=1):
        cur = resolve(cfg, shot)
        cur_s = str(cur.relative_to(media)) if cur else "— none yet —"
        lines.append(f"| {n} | `{shot['id']}` | {shot.get('screen', plain(shot['headline']))} | {cur_s} |")
    notes = cfg.get("capture_notes")
    if notes:
        lines += ["", "## Notes", "", notes]
    (folder / "SHOTLIST.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(folder)


def cmd_verify(cfg, args):
    newest = media_dirs(cfg)[:1]
    missing = 0
    for n, shot in enumerate(cfg["shots"], start=1):
        src = resolve(cfg, shot)
        if src is None:
            missing += 1
            print(f"{n:2}. {shot['id']:<24} MISSING")
            continue
        with Image.open(src) as im:
            w, h = im.size
        flags = []
        if newest and src.parent == newest[0]:
            flags.append("new")
        if h < w:
            flags.append("LANDSCAPE?")
        elif not 1.9 <= h / w <= 2.3:
            flags.append(f"aspect {h / w:.2f}, expected a phone ~2.17")
        if w < 1080:
            flags.append(f"only {w}px wide")
        print(f"{n:2}. {shot['id']:<24} {src.parent.name}/{src.name}  {w}x{h}  {' · '.join(flags)}")
    if missing:
        sys.exit(f"{missing} shot(s) have no raw screenshot.")


def cmd_compose(cfg, args):
    for key, out in cfg.get("outputs", {}).items():
        folder = rel(cfg, out["dir"])
        folder.mkdir(parents=True, exist_ok=True)
        pattern = out.get("name", "{n:02d}_{id}.png")
        # Replace the previous set: remove only files this pattern could have written.
        glob = re.sub(r"\{[^}]*\}", "*", pattern)
        for old in folder.glob(glob):
            old.unlink()
        size = tuple(out["size"])
        for n, shot in enumerate(cfg["shots"], start=1):
            src = resolve(cfg, shot)
            compose(cfg, shot, size).save(folder / out_name(pattern, n, shot, src), optimize=True)
        print(f"{key}: {len(cfg['shots'])} screenshots, {size[0]}x{size[1]} -> {folder}")


def cmd_web(cfg, args):
    web = cfg.get("website")
    if not web:
        sys.exit("No \"website\" section in the config.")
    folder = rel(cfg, web["static_repo"]) / web["static_dir"]
    folder.mkdir(parents=True, exist_ok=True)
    width = web.get("width", 1179)
    shots = [s for s in cfg["shots"] if s.get("web", True)]
    listing = []
    for shot in shots:
        img = prepared(cfg, shot)
        img = img.resize((width, int(img.height * width / img.width)), Image.LANCZOS)
        name = f"{shot['id']}.jpg"
        img.save(folder / name, quality=web.get("jpeg_quality", 85), optimize=True)
        listing.append({
            "src": f"{web['url_prefix'].rstrip('/')}/{name}",
            "title": plain(shot.get("web_title", shot["headline"])),
            "caption": shot.get("web_caption", shot["subline"]),
        })
    print(f"{len(shots)} website images -> {folder}", file=sys.stderr)
    print(json.dumps(listing, indent=2, ensure_ascii=False))


def cmd_text(cfg, args):
    over = 0
    for store, folder in cfg.get("text", {}).items():
        folder = rel(cfg, folder)
        print(f"[{store}] {folder}")
        for name, limit in LIMITS.get(store, {}).items():
            f = folder / name
            if not f.exists():
                print(f"  {name:<24} (missing)")
                continue
            n = len(f.read_text(encoding="utf-8").strip())
            mark = "  OVER" if n > limit else ""
            over += n > limit
            print(f"  {name:<24} {n:>5} / {limit}{mark}")
    if over:
        sys.exit(f"{over} field(s) over the store limit.")


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("command", choices=["checklist", "verify", "compose", "web", "text"])
    p.add_argument("--root", default=".", help="the app repo (default: current directory)")
    p.add_argument("--config", default="distribution/assets.md", help="relative to --root")
    args = p.parse_args()
    root = Path(args.root).expanduser().resolve()
    cfg = load_config(root, root / args.config)
    {"checklist": cmd_checklist, "verify": cmd_verify, "compose": cmd_compose,
     "web": cmd_web, "text": cmd_text}[args.command](cfg, args)


if __name__ == "__main__":
    main()
