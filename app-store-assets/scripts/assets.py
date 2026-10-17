#!/usr/bin/env python3
"""
App store assets: screenshots for the App Store, Google Play and the app's website,
from a pool of raw phone screenshots and a caption library.

Captures live in dated folders (<media_dir>/YYYY-MM-DD/). The newest folder is the
working set, and its file names decide what is published and in what order:
    1_home.png, 2_coach.png ...   published in number order (gaps are fine)
    extra_scorecard.png            a candidate: kept, not published
    anything else                  unsorted: look at it and rename it
Older folders are history and are never renamed; every shot in them is a candidate
(unless the working set has the same id). `checklist` starts today's folder by copying
in the published set, so only changed screens need replacing.
The part after the prefix is the shot's id. Captions come from the config's "shots",
keyed by id.

Everything app-specific (paths, captions, colours, website) lives in the app's own
config file, a Markdown file with one ```json block (see templates/assets.md). This
script is the generic part and contains no app's details.

    python3 assets.py checklist   # make today's capture folder + SHOTLIST.md
    python3 assets.py verify      # published (in order), extras, unsorted; problems
    python3 assets.py sheet       # contact sheet of the pool, to choose from
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
import shutil
import sys
from pathlib import Path

try:
    from PIL import Image, ImageDraw, ImageFilter, ImageFont
except ImportError:
    sys.exit("Pillow is required: pip install Pillow")

RAW_EXTS = (".png", ".jpg", ".jpeg")
DATED = re.compile(r"^\d{4}-\d{2}-\d{2}$")
# "3_scorecard" -> published #3, id "scorecard"; "extra_scorecard" -> candidate.
NAMED = re.compile(r"^(?:(?P<n>\d+)|extra)_(?P<id>.+)$", re.I)
# Most phone screenshots each store accepts (override with "max" on an output).
STORE_MAX = {"ios": 10, "play": 8}

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
    cfg.setdefault("shots", [])
    cfg["_root"] = root
    return cfg


def rel(cfg, p) -> Path:
    """Paths in the config are relative to the app repo; ~ is expanded."""
    p = Path(str(p)).expanduser()
    return p if p.is_absolute() else cfg["_root"] / p


def media_root(cfg) -> Path:
    return rel(cfg, cfg.get("media_dir", "distribution/media"))


def rgb(hex_colour: str):
    h = hex_colour.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def plain(text: str) -> str:
    return text.replace("*", "")


# ---------------------------------------------------------------------------
# The pool


class Raw:
    """One raw screenshot: its file, its publish number (None for candidates) and its id."""

    def __init__(self, path: Path, number, shot_id: str):
        self.path, self.number, self.id = path, number, shot_id

    @property
    def selected(self) -> bool:
        return self.number is not None

    @property
    def where(self) -> str:
        return f"{self.path.parent.name}/{self.path.name}"


def media_dirs(cfg):
    """Capture folders, newest first (YYYY-MM-DD names sort by date)."""
    media = media_root(cfg)
    if not media.is_dir():
        return []
    return sorted((d for d in media.iterdir() if d.is_dir() and DATED.match(d.name)), reverse=True)


def images(folder: Path):
    return [f for f in sorted(folder.iterdir()) if f.suffix.lower() in RAW_EXTS]


def parse(f: Path):
    """(number or None, id) for a named file; None for an unsorted one."""
    m = NAMED.match(f.stem)
    if not m:
        return None
    return (int(m.group("n")) if m.group("n") else None), m.group("id")


def pool(cfg):
    """The working folder's shots, history candidates, and the working folder's unsorted files.

    Returns (working, candidates, unsorted): working is every named file in the newest
    folder; candidates are older shots whose id isn't in the working folder (newest copy
    of each); unsorted are unnamed files in the working folder."""
    dirs = media_dirs(cfg)
    if not dirs:
        return [], [], []
    working, unsorted = [], []
    for f in images(dirs[0]):
        parsed = parse(f)
        if parsed is None:
            unsorted.append(f)
        else:
            working.append(Raw(f, *parsed))
    taken = {r.id for r in working}
    candidates = {}
    for d in dirs[1:]:  # newest first, so the first copy of an id wins
        for f in images(d):
            parsed = parse(f)
            shot_id = parsed[1] if parsed else f.stem
            if shot_id not in taken and shot_id not in candidates:
                candidates[shot_id] = Raw(f, None, shot_id)
    return working, sorted(candidates.values(), key=lambda r: r.id), unsorted


def extras(cfg):
    """Every candidate: the working folder's extra_ files, then history."""
    working, history, _ = pool(cfg)
    return sorted((r for r in working if not r.selected), key=lambda r: r.id) + history


def selection(cfg, strict=True):
    """The published raws in order, each with its caption entry; plus any problems."""
    working, _, _ = pool(cfg)
    chosen = sorted((r for r in working if r.selected), key=lambda r: r.number)
    shots = {s["id"]: s for s in cfg["shots"]}
    problems, seen = [], {}
    for r in chosen:
        if r.number in seen:
            problems.append(f"#{r.number} is used twice: {seen[r.number].path.name} and {r.path.name}")
        seen[r.number] = r
        s = shots.get(r.id, {})
        if not s.get("headline") or not s.get("subline"):
            problems.append(f"'{r.id}' has no headline/subline in the config's shots")
    if not chosen:
        problems.append("nothing is selected: in the newest capture folder, name the shots to "
                        "publish 1_<id>.png, 2_<id>.png, …")
    if strict and problems:
        sys.exit("\n".join(problems))
    return [(r, shots.get(r.id, {"id": r.id})) for r in chosen], problems


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


def prepared(cfg, raw, shot):
    """The raw screen with blurs applied and the status bar cropped."""
    img = Image.open(raw.path).convert("RGB")
    for box in shot.get("blur", []):
        box = tuple(box)
        img.paste(img.crop(box).filter(ImageFilter.GaussianBlur(14)), box)
    return img.crop((0, cfg["style"]["status_bar_px"], img.width, img.height))


def compose(cfg, raw, shot, size):
    style = cfg["style"]
    width, _ = size
    screen = prepared(cfg, raw, shot)

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


def size_flags(cfg, path: Path):
    with Image.open(path) as im:
        w, h = im.size
    flags = []
    newest = media_dirs(cfg)[:1]
    if newest and path.parent == newest[0]:
        flags.append("new")
    if h < w:
        flags.append("LANDSCAPE?")
    elif not 1.9 <= h / w <= 2.3:
        flags.append(f"aspect {h / w:.2f}, expected a phone ~2.17")
    if w < 1080:
        flags.append(f"only {w}px wide")
    return f"{w}x{h}  {' · '.join(flags)}"


# ---------------------------------------------------------------------------
# Commands


def cmd_checklist(cfg, args):
    folder = media_root(cfg) / dt.date.today().isoformat()
    if not folder.exists():
        # Start today's working set from the current published set (read before today's
        # folder exists, so it comes from the previous working set); history stays put.
        published = [r for r in pool(cfg)[0] if r.selected]
        folder.mkdir(parents=True)
        for r in published:
            shutil.copy2(r.path, folder / r.path.name)
    folder.mkdir(parents=True, exist_ok=True)
    chosen, _ = selection(cfg, strict=False)
    shots = {s["id"]: s for s in cfg["shots"]}
    describe = lambda i: shots.get(i, {}).get("screen") or plain(shots.get(i, {}).get("headline", ""))
    lines = [
        f"# Screenshots: {cfg.get('app', 'app')}",
        "",
        "This folder is today's working set: it starts with a copy of what's published now.",
        "Replace a screen by saving over its file. File names decide what is published:",
        "",
        "- `1_<id>.png`, `2_<id>.png`, …: published, left to right in number order.",
        "- `extra_<id>.png`: a candidate, kept but not published.",
        "- Any other name (e.g. `IMG_1234.PNG`) is fine; the agent will look at it and name it.",
        "",
        "Older folders are history; anything in them can be copied back in.",
        "",
        "## Published now",
        "",
        "| # | File name | Screen | Current capture |",
        "|---|---|---|---|",
    ]
    lines += [f"| {n} | `{r.path.name}` | {describe(r.id)} | {r.where} |"
              for n, (r, _) in enumerate(chosen, start=1)]
    spare = extras(cfg)
    if spare:
        lines += ["", "## Candidates", "", "| Id | Screen | Capture |", "|---|---|---|"]
        lines += [f"| `{r.id}` | {describe(r.id)} | {r.where} |" for r in spare]
    if cfg.get("capture_notes"):
        lines += ["", "## Notes", "", cfg["capture_notes"]]
    (folder / "SHOTLIST.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(folder)


def cmd_verify(cfg, args):
    _, _, unsorted = pool(cfg)
    chosen, problems = selection(cfg, strict=False)
    dirs = media_dirs(cfg)
    print(f"Working set: {dirs[0].name if dirs else '(none)'}")
    print("Published, in order:")
    for n, (r, _) in enumerate(chosen, start=1):
        print(f"  {n:2}. {r.id:<28} {r.where}  {size_flags(cfg, r.path)}")
    spare = extras(cfg)
    if spare:
        print("Candidates (not published):")
        for r in spare:
            print(f"      {r.id:<28} {r.where}  {size_flags(cfg, r.path)}")
    if unsorted:
        print("Unsorted (rename to N_<id> or extra_<id>):")
        for f in unsorted:
            print(f"      {f.parent.name}/{f.name}")
    for store, out in cfg.get("outputs", {}).items():
        cap = out.get("max", STORE_MAX.get(store))
        if cap and len(chosen) > cap:
            problems.append(f"{len(chosen)} selected, but {store} takes at most {cap}")
    if problems:
        sys.exit("Problems:\n" + "\n".join(f"  - {p}" for p in problems))


def cmd_sheet(cfg, args):
    """A labelled grid: published (outlined, in order), candidates, unsorted."""
    _, _, unsorted = pool(cfg)
    chosen, _ = selection(cfg, strict=False)
    items = [(f"{n}  {r.id}", r.path, True) for n, (r, _) in enumerate(chosen, start=1)]
    items += [(f"extra  {r.id}", r.path, False) for r in extras(cfg)]
    items += [(f"?  {f.name}", f, False) for f in unsorted]
    if not items:
        sys.exit("The pool is empty.")
    thumb_w, label_h, gap = 300, 64, 28
    cols = min(6, len(items))
    thumbs = []
    for label, path, sel in items:
        im = Image.open(path).convert("RGB")
        thumbs.append((label, im.resize((thumb_w, int(im.height * thumb_w / im.width)), Image.LANCZOS), sel))
    cell_h = max(im.height for _, im, _ in thumbs) + label_h
    rows = (len(thumbs) + cols - 1) // cols
    sheet = Image.new("RGB", (gap + cols * (thumb_w + gap), gap + rows * (cell_h + gap)), (24, 24, 24))
    draw = ImageDraw.Draw(sheet)
    try:
        font = ImageFont.truetype(cfg["style"]["font"], 22, index=cfg["style"]["headline_font_index"])
    except OSError:
        font = ImageFont.load_default()
    for i, (label, im, sel) in enumerate(thumbs):
        x, y = gap + (i % cols) * (thumb_w + gap), gap + (i // cols) * (cell_h + gap)
        colour = rgb(cfg["style"]["accent"]) if sel else (175, 175, 175)
        while draw.textlength(label, font=font) > thumb_w and len(label) > 4:
            label = label[:-2] + "…"  # keep labels inside their column
        draw.text((x, y + 20), label, font=font, fill=colour)
        sheet.paste(im, (x, y + label_h))
        if sel:
            draw.rectangle((x - 5, y + label_h - 5, x + thumb_w + 4, y + label_h + im.height + 4),
                           outline=colour, width=5)
    out = media_root(cfg) / "contact-sheet.png"
    sheet.save(out, optimize=True)
    print(out)


def cmd_compose(cfg, args):
    chosen, _ = selection(cfg)
    for key, out in cfg.get("outputs", {}).items():
        folder = rel(cfg, out["dir"])
        folder.mkdir(parents=True, exist_ok=True)
        pattern = out.get("name", "{n:02d}_{id}.png")
        # Replace the previous set: remove only files this pattern could have written.
        for old in folder.glob(re.sub(r"\{[^}]*\}", "*", pattern)):
            old.unlink()
        size = tuple(out["size"])
        for n, (raw, shot) in enumerate(chosen, start=1):
            name = pattern.format(n=n, id=raw.id, stem=raw.path.stem)
            compose(cfg, raw, shot, size).save(folder / name, optimize=True)
        print(f"{key}: {len(chosen)} screenshots, {size[0]}x{size[1]} -> {folder}")


def cmd_web(cfg, args):
    web = cfg.get("website")
    if not web:
        sys.exit("No \"website\" section in the config.")
    chosen, _ = selection(cfg)
    folder = rel(cfg, web["static_repo"]) / web["static_dir"]
    folder.mkdir(parents=True, exist_ok=True)
    width = web.get("width", 1179)
    listing = []
    for raw, shot in chosen:
        if shot.get("web") is False:
            continue
        img = prepared(cfg, raw, shot)
        img = img.resize((width, int(img.height * width / img.width)), Image.LANCZOS)
        name = f"{raw.id}.jpg"
        img.save(folder / name, quality=web.get("jpeg_quality", 85), optimize=True)
        listing.append({
            "src": f"{web['url_prefix'].rstrip('/')}/{name}",
            "title": plain(shot.get("web_title", shot["headline"])),
            "caption": shot.get("web_caption", shot["subline"]),
        })
    print(f"{len(listing)} website images -> {folder}", file=sys.stderr)
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


COMMANDS = {"checklist": cmd_checklist, "verify": cmd_verify, "sheet": cmd_sheet,
            "compose": cmd_compose, "web": cmd_web, "text": cmd_text}


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("command", choices=list(COMMANDS))
    p.add_argument("--root", default=".", help="the app repo (default: current directory)")
    p.add_argument("--config", default="distribution/assets.md", help="relative to --root")
    args = p.parse_args()
    root = Path(args.root).expanduser().resolve()
    COMMANDS[args.command](load_config(root, root / args.config), args)


if __name__ == "__main__":
    main()
