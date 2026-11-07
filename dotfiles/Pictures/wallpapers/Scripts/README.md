# wallpaper-theme-sort

A small command-line tool that analyzes a folder of wallpapers, detects each
image's dominant colors, and sorts it into subfolders named after popular Linux
color schemes (Catppuccin, Dracula, Nord, Gruvbox, Tokyo Night, etc.).

It can also rename the files to descriptive names such as
`gruvbox-dark-orange-purple-01.png`.

- No image-editing libraries required — only **Python 3** and **ffmpeg**.
- Images are never modified or deleted. They are moved and/or copied.
- Everything is local; nothing is uploaded anywhere.

---

## Table of contents

1. [What it does](#what-it-does)
2. [Requirements](#requirements)
3. [Files and folders](#files-and-folders)
4. [Installation](#installation)
5. [Quick start](#quick-start)
6. [Usage](#usage)
7. [Options](#options)
8. [How the matching works](#how-the-matching-works)
9. [Supported themes](#supported-themes)
10. [File naming](#file-naming)
11. [Multi-theme behavior](#multi-theme-behavior)
12. [Reports](#reports)
13. [Renaming an existing library](#renaming-an-existing-library)
14. [Customization](#customization)
15. [Troubleshooting](#troubleshooting)
16. [Limitations](#limitations)
17. [Backup and undo](#backup-and-undo)
18. [Performance](#performance)
19. [FAQ](#faq)

---

## What it does

For every image directly inside the target folder, the script:

1. Downscales it and extracts a compact dominant-color palette.
2. Compares that palette with the official accent palettes of 10 popular themes.
3. Picks the best-matching theme (and optionally up to 2 close runner-ups).
4. Moves the image into the best theme's folder and copies it into the other
   matching theme folders.
5. Renames the file using the theme, tone, and dominant colors.
6. Writes a text report mapping original names to final locations.

Near-grayscale images are placed in a `Monochrome` folder instead of being
forced into a color scheme.

---

## Requirements

| Requirement | Notes |
|---|---|
| **Python 3.8+** | Uses only the standard library. |
| **ffmpeg** | Must be available in `PATH` (`ffmpeg -version` should work). |
| **Linux** | Tested on Linux; should also work on macOS/BSD with ffmpeg installed. |

No `pip install` is needed. Pillow, ImageMagick, and similar tools are **not**
required.

Check your setup:

```bash
python3 --version
ffmpeg -version
```

---

## Files and folders

```text
~/Pictures/wallpapers/
├── Scripts/
│   ├── wallpaper-theme-sort     # this script
│   └── README.md                # this file
├── Catppuccin/                  # created by the script
├── Dracula/
├── Everforest/
├── Gruvbox/
├── Kanagawa/
├── Monochrome/
├── Nord/
├── One Dark/
├── Rose Pine/
├── Solarized/
└── Tokyo Night/
```

The script only scans **image files directly inside the target folder**. It does
not descend into the theme subfolders or into `Scripts/`, so it is safe to keep
the script there.

---

## Installation

The script is already executable. If needed:

```bash
chmod +x ~/Pictures/wallpapers/Scripts/wallpaper-theme-sort
```

Run it with its full path:

```bash
~/Pictures/wallpapers/Scripts/wallpaper-theme-sort --help
```

### Optional: make it available as a command

Create a symlink somewhere in your `PATH`, for example:

```bash
mkdir -p ~/.local/bin
ln -sf ~/Pictures/wallpapers/Scripts/wallpaper-theme-sort ~/.local/bin/wallpaper-theme-sort
```

If `~/.local/bin` is not in your `PATH`, add this to `~/.bashrc` (or your
shell's config):

```bash
export PATH="$HOME/.local/bin:$PATH"
```

Then reload the shell:

```bash
source ~/.bashrc
```

After that you can run:

```bash
wallpaper-theme-sort --dry-run
```

---

## Quick start

Always preview first:

```bash
~/Pictures/wallpapers/Scripts/wallpaper-theme-sort --dry-run
```

If the matches look reasonable, run it for real:

```bash
~/Pictures/wallpapers/Scripts/wallpaper-theme-sort
```

The default target is `~/Pictures/wallpapers`. To sort a different folder:

```bash
~/Pictures/wallpapers/Scripts/wallpaper-theme-sort ~/Pictures/other-wallpapers
```

---

## Usage

```text
wallpaper-theme-sort [directory] [options]
```

- `directory` — folder containing images. Default: `~/Pictures/wallpapers`.
- Only top-level files with these extensions are considered:
  `.png`, `.jpg`, `.jpeg`, `.webp`, `.bmp`, `.tif`, `.tiff`
  (case-insensitive).

Examples (run from `~/Pictures/wallpapers/Scripts`, or use the full path):

```bash
# Preview matches and planned filenames
./wallpaper-theme-sort --dry-run

# Sort + rename the default folder
./wallpaper-theme-sort

# Sort another folder
./wallpaper-theme-sort ~/Downloads/walls

# Keep original filenames
./wallpaper-theme-sort --no-rename

# Keep originals in place and copy into every matching folder
./wallpaper-theme-sort --copy

# Allow up to 4 themes per image
./wallpaper-theme-sort --max-themes 4

# Be stricter about runner-up matches
./wallpaper-theme-sort --rel 0.92 --abs 0.30

# Treat more images as monochrome
./wallpaper-theme-sort --mono 0.10
```

---

## Options

| Option | Default | Description |
|---|---:|---|
| `directory` | `~/Pictures/wallpapers` | Folder to scan. |
| `--dry-run` | off | Analyze and print results, change nothing. |
| `--copy` | off | Keep originals and copy into every matching folder. Without this, the best match is **moved** and runner-ups get **copies**. |
| `--max-themes N` | `3` | Maximum number of folders per image. |
| `--rel F` | `0.85` | A runner-up must score at least `F × top_score` to be included. |
| `--abs F` | `0.22` | Minimum absolute score for a runner-up theme. |
| `--mono F` | `0.06` | Images with a chromatic-pixel fraction below `F` go to `Monochrome`. |
| `--report NAME` | `theme-sort-report.txt` | Report filename inside the target folder. |
| `--no-rename` | off | Keep original filenames. |
| `--rename-existing` | off | Rename images already inside theme folders, in place. No sorting/moving. |
| `-h`, `--help` | — | Show the built-in help. |

---

## How the matching works

The goal is a fast, dependency-free heuristic — not an AI model. It works well
for colorful wallpapers and is intentionally conservative about assigning
multiple themes.

### 1. Downscale

Each image is decoded with ffmpeg and scaled to **96×54** pixels using area
averaging. This keeps analysis fast and smooths out noise.

### 2. Convert to CIELAB

Every sampled pixel is converted from sRGB to **CIELAB** (D65 white point).
CIELAB is designed so that numeric distance roughly matches perceived color
difference.

### 3. Build a palette with k-means

The pixels are clustered with **k-means++** into up to **10** dominant colors.
Each cluster stores:

- its average color (in Lab),
- its share of the image (weight).

### 4. Build a hue histogram

Each palette color is converted to **LCh** (lightness, chroma, hue). Colors with
chroma above 9 contribute to a **36-bin hue histogram**, weighted by their image
share and by chroma (capped at 60). Contributions are softened into neighboring
bins (70% center, 15% each side).

Neutral/near-gray pixels do not contribute to hue. Their total weight is used
separately to estimate how dark the image is.

### 5. Compare with theme profiles

Each theme has an official accent palette plus a background color. Signature
colors get extra weight, for example:

- Dracula: vivid purple and pink matter most.
- Nord: frost blues and cool blues matter most.
- Gruvbox: warm orange/yellow/red matter most.
- Everforest: muted greens matter most.

The image histogram is compared with each theme histogram using **histogram
intersection**:

```text
similarity = Σ min(image_bin[i], theme_bin[i])
```

The result is adjusted by two factors:

- **Vividness bonus** — muted themes (Nord, Catppuccin, Everforest, Rose Pine)
  get a small penalty for extremely saturated images; vivid themes (Dracula,
  Tokyo Night, One Dark) get a small bonus.
- **Tone factor** — images with a large dark mass get a small boost for the
  dark background that all these themes share.

### 6. Choose themes

- The **highest-scoring theme is always assigned**.
- A runner-up is added only if:
  - its score is at least `--abs`, **and**
  - its score is at least `--rel × top_score`.
- At most `--max-themes` themes are assigned.
- If the chromatic-pixel fraction is below `--mono`, the image goes to
  `Monochrome` instead.

### 7. Sort and rename

Without `--copy`:

- the image is **moved** into the best theme's folder,
- then **copied** into each additional matching folder.

With `--copy`, the original stays where it is and every placement is a copy.

Collisions are handled safely: if the primary destination already exists, that
image is skipped and counted in the report summary; if an extra copy's name
already exists, a `-2`, `-3`, … suffix is added. Nothing is overwritten.

---

## Supported themes

| Folder | Style | Signature colors |
|---|---|---|
| `Catppuccin` | Soft pastel | mauve `#cba6f7`, pink `#f5c2e7`, blue `#89b4fa`, red `#f38ba8`, green `#a6e3a1` |
| `Dracula` | Vivid dark purple/pink | purple `#bd93f9`, pink `#ff79c6`, cyan `#8be9fd`, green `#50fa7b` |
| `Nord` | Cool arctic blue-gray | frost `#88c0d0`, `#81a1c1`, `#5e81ac`, teal `#8fbcbb` |
| `Gruvbox` | Warm retro | orange `#fe8019`, yellow `#fabd2f`, red `#fb4934`, green `#b8bb26` |
| `Tokyo Night` | Deep blue + neon | blue `#7aa2f7`, purple `#bb9af7`, cyan `#2ac3de`, pink `#f7768e` |
| `Everforest` | Muted forest green | green `#a7c080`, aqua `#7fbbb3`, `#83c092`, yellow `#dbbc7f` |
| `Solarized` | Warm dark teal | blue `#268bd2`, cyan `#2aa198`, yellow `#b58900`, orange `#cb4b16` |
| `One Dark` | Neutral charcoal | blue `#61afef`, green `#98c379`, red `#e06c75`, purple `#c678dd` |
| `Rose Pine` | Muted pink/purple | iris `#c4a7e7`, love `#eb6f92`, foam `#9ccfd8`, gold `#f6c177` |
| `Kanagawa` | Japanese indigo | wave `#7e9cd8`, purple `#957fb8`, pink `#d27e99`, orange `#ffa066` |
| `Monochrome` | Grayscale | any image below the `--mono` threshold |

The full accent lists are in the `THEMES` dictionary at the top of the script.

---

## File naming

With renaming enabled (the default), each placement gets a name like:

```text
<theme>-<tone>-<color1>[-<color2>]-<number>.<ext>
```

Examples:

```text
gruvbox-dark-orange-purple-01.png
tokyo-night-blue-red-03.png
catppuccin-light-pink-02.png
monochrome-dark-gray-04.png
```

Rules:

- **Theme** — lowercased folder name with spaces replaced by hyphens
  (`Tokyo Night` → `tokyo-night`, `One Dark` → `one-dark`).
- **Tone** — `dark` if the image's mean Lab lightness is below 22, `light` if
  above 62, otherwise omitted.
- **Colors** — up to two dominant chromatic color names, mapped from Lab hue:
  `red`, `orange`, `yellow`, `green`, `cyan`, `blue`, `purple`, `pink`.
- **Number** — two-digit sequence within that theme folder, assigned in sorted
  original-filename order (`01`, `02`, …).
- **Monochrome** — always uses `gray`, e.g. `monochrome-dark-gray-01.png`.
- **Extension** — preserved, lowercased.
- **Collisions** — if the name already exists, `-2`, `-3`, … is appended.

> Because numbers are assigned per folder in filename order, adding or removing
> files can change the numbering the next time you rename an existing library.
> If you need stable names, rename once and then avoid re-running
> `--rename-existing` on that folder.

### Same image, different folders

An image that matches multiple themes gets a theme-specific name in each folder:

```text
Kanagawa/kanagawa-blue-05.png
Catppuccin/catppuccin-blue-03.png
Nord/nord-blue-02.png
```

This is intentional: the filename always agrees with the folder it is in.

---

## Multi-theme behavior

Suppose an image's scores are:

```text
Kanagawa 0.33 | Catppuccin 0.30 | Nord 0.30 | Gruvbox 0.24
```

With defaults (`--max-themes 3`, `--rel 0.85`, `--abs 0.22`):

- Kanagawa is the best match.
- Catppuccin and Nord are close enough, so they are included.
- Gruvbox is too far below the top score, so it is excluded.

Result:

- the original file is **moved** to `Kanagawa/`,
- copies are placed in `Catppuccin/` and `Nord/`.

If you want a strict one-folder-per-image sort, use:

```bash
--max-themes 1
```

If you want more aggressive cross-posting, lower the thresholds:

```bash
--rel 0.80 --abs 0.18 --max-themes 3
```

---

## Reports

### `theme-sort-report.txt`

Written after a normal sort (name configurable with `--report`). It maps each
original filename to its final theme/filename placements:

```text
wallhaven-example_1920x1080.png
    -> Gruvbox/gruvbox-dark-orange-purple-01.png, Everforest/everforest-dark-orange-02.png

Original images: 43
Total placements: 56
```

This is the primary record of what happened. Keep it if you care about tracing
renamed files back to their original names.

### `rename-report.txt`

Written by `--rename-existing`. It records old path → new path for every renamed
file:

```text
Gruvbox/wallhaven-example_1920x1080.png
    -> Gruvbox/gruvbox-dark-orange-purple-01.png
```

### Where reports live

Reports are written inside the **target directory**, not next to the script.
For the default target, that is `~/Pictures/wallpapers/`.

You can rename the normal report:

```bash
./wallpaper-theme-sort --report .sort-report.txt
```

Delete reports whenever you like — they are not required for the script to
work.

---

## Renaming an existing library

If the images are already sorted into theme folders and you only want to rename
them:

```bash
~/Pictures/wallpapers/Scripts/wallpaper-theme-sort ~/Pictures/wallpapers --rename-existing
```

What it does:

1. Scans every known theme folder in the target directory.
2. Groups identical files by MD5 so each unique image is analyzed only once.
3. Re-analyzes the palette of each unique image.
4. Renames files in place using the descriptive naming scheme.
5. Writes `rename-report.txt` in the target directory.

Important notes:

- It **does not** move files between folders or change their theme assignment.
- It renames **immediately**; `--dry-run` is currently ignored in this mode.
  Make a backup first if the library is important.
- Running it twice will renumber files, because numbering is based on the
  current filenames. Run it once unless you add new images.
- Only files directly inside the theme folders are touched.

---

## Customization

The script is intentionally a single file with no config file. Edit the copy in
`~/Pictures/wallpapers/Scripts/`.

### Add a new theme

Add an entry to the `THEMES` dictionary:

```python
"Nightfox": {
    "bg": "#192330",
    "accents": ["#719cd6", "#63cdcf", "#dbc074", "#c94f6d", "#81b29a", "#9d79d6"],
},
```

Optionally add signature weights to `SIGNATURE`:

```python
"Nightfox": {"#719cd6": 4, "#63cdcf": 3, "#9d79d6": 3},
```

The folder name comes from the dictionary key. `THEME_ORDER` is built
automatically. No other change is needed.

### Change the thresholds

Either use the CLI options (`--rel`, `--abs`, `--mono`, `--max-themes`) or edit
their defaults in `main()`.

### Change the naming style

Edit `descriptive_name()`:

- remove the `parts.append("dark"/"light")` lines to drop the tone,
- change the number of colors by changing `if len(colors) == 2`,
- remove the theme prefix if you prefer `dark-orange-01.png`,
- change the number width with `f"{seq:02d}"`.

Color names are defined in `color_name()`. Lab hue ranges are:

| Hue range | Name |
|---|---|
| 0–55 | `red` |
| 55–80 | `orange` |
| 80–110 | `yellow` |
| 110–170 | `green` |
| 170–230 | `cyan` |
| 230–300 | `blue` |
| 300–330 | `purple` |
| 330–360 | `pink` |

### Change the analysis resolution

In `analyze()`:

```python
def analyze(path, width=96, height=54):
```

Higher values are slightly more accurate but slower. 96×54 is plenty for
dominant-color work.

### Change k-means palette size

Inside `analyze()`:

```python
"palette": kmeans(pts, 10),
```

Increase `10` for more palette detail, decrease for speed.

### Add more file extensions

Edit `IMAGE_EXT` near the top:

```python
IMAGE_EXT = (".png", ".jpg", ".jpeg", ".webp", ".bmp", ".tif", ".tiff", ".avif")
```

Make sure ffmpeg can decode the format.

---

## Troubleshooting

| Problem | Cause / fix |
|---|---|
| `ffmpeg: command not found` | Install ffmpeg with your package manager, e.g. `sudo pacman -S ffmpeg`, `sudo apt install ffmpeg`, or `sudo dnf install ffmpeg`. |
| `No images found directly in ...` | Images are inside subfolders. The script only scans top-level files; pass the correct folder or move images to its root. |
| `Permission denied` | Run `chmod +x wallpaper-theme-sort`, or invoke it as `python3 wallpaper-theme-sort`. |
| `command not found` when using the short name | The script is not in `PATH`. Use the full path or add `~/.local/bin` to `PATH`. |
| Wrong theme assignments | The matcher is a color heuristic, not semantic understanding. Tune `--rel`, `--abs`, `--max-themes`, or add/adjust signature colors. |
| Too many folders per image | Use `--max-themes 1` or raise `--rel` / `--abs`. |
| Too few matches | Lower `--rel` / `--abs` or raise `--max-themes`. |
| A grayscale image ended up in a color theme | Lower `--mono` (e.g. `0.04`) or move it manually. |
| A colored image ended up in `Monochrome` | Lower the threshold (e.g. `--mono 0.03`) so fewer images count as gray. |
| `SKIP (already exists)` | A file with the same final name is already in the destination folder. Remove/rename it or use `--no-rename`. |
| Report file clutters the wallpaper root | Use `--report .sort-report.txt`, or delete the report after reviewing it. |
| Renaming renumbered my files | `--rename-existing` numbers by current filename order. Avoid re-running it, or back up names first. |
| Analysis feels slow | Each image is decoded once; expect roughly 0.5–2 seconds per image. Large libraries take a few minutes. |

---

## Limitations

- **Color, not content.** The script does not know whether a wallpaper is a
  landscape, anime character, car, or abstract art. It only sees color.
- **Themes overlap.** Several schemes share blues, purples, and pinks. Close
  scores are expected; thresholds decide how many folders an image enters.
- **Flat backgrounds dominate.** An image that is 70% flat red will be treated
  as a red image, even if the subject is something else.
- **Muted vs vivid is approximate.** The vividness adjustment is a heuristic,
  not a perfect model of each theme's mood.
- **Grayscale cutoff is binary.** `--mono` is a simple threshold; borderline
  images can land on either side.
- **No duplicate detection during a normal sort.** Duplicate files at the top
  level are analyzed and moved like any other file. `--rename-existing` does
  deduplicate by MD5 for analysis, but still renames each placement.
- **No undo command.** The script moves files and writes reports; reversing a
  run is a manual job using the report mapping.
- **Filenames are not stable across re-runs** when renaming is enabled and the
  set of files changes.
- **It creates all known theme folders** on a normal run, even if some end up
  empty. Empty folders are harmless and can be removed.
- **It does not download wallpapers or set them as your desktop background.**
  It only organizes files.

---

## Backup and undo

Before a large sort, make a safety copy:

```bash
cp -a ~/Pictures/wallpapers ~/Pictures/wallpapers-backup-$(date +%F)
```

The script never deletes images, but it does move and rename them. If you need
to undo:

1. Open `theme-sort-report.txt` (normal sort) or `rename-report.txt`
   (`--rename-existing`).
2. Each entry shows the original name and the final path.
3. Move the files back and restore the original names manually.

If you only want to try the script without committing, always start with:

```bash
./wallpaper-theme-sort --dry-run
```

Or use `--copy`, which leaves the originals untouched:

```bash
./wallpaper-theme-sort --copy
```

---

## Performance

- One ffmpeg decode per image, downscaled to 96×54.
- One k-means run over 5,184 pixels (10 clusters, 14 iterations, fixed seed).
- Single-threaded Python.
- Typical result: **~0.5–2 seconds per image**, depending on disk and image
  format. A 50-image library usually finishes in under a minute.
- Memory use is small; images are never loaded at full resolution.

---

## FAQ

**Does it delete anything?**
No. It only moves and copies files. Existing destination files are never
overwritten: a primary-name collision skips the image, and secondary-copy
collisions get a `-2`, `-3`, … suffix.

**Does it modify the images themselves?**
No. The images are decoded read-only for analysis; the files are moved or
copied byte-for-byte.

**Does it support JPG/WebP?**
Yes, plus PNG, BMP, and TIFF (as long as ffmpeg can decode them).

**Can I run it on a folder other than `~/Pictures/wallpapers`?**
Yes:

```bash
./wallpaper-theme-sort /path/to/walls
```

**Can I keep the original filenames?**
Yes:

```bash
./wallpaper-theme-sort --no-rename
```

**Can I keep the originals and only make copies?**
Yes:

```bash
./wallpaper-theme-sort --copy
```

**Can I add my own theme?**
Yes — add it to `THEMES` and optionally `SIGNATURE`, as shown in
[Customization](#customization).

**Can I use this for a non-Linux setup?**
It should work anywhere Python 3 and ffmpeg are available, including macOS.
Windows is untested but likely works if ffmpeg is in `PATH`.

**Why is there a `Monochrome` folder if it is not a color scheme?**
Because near-grayscale wallpapers do not meaningfully match a color palette, and
forcing them into one would be misleading. They are still useful wallpapers, so
they get their own category.

**Why did one image go into three folders?**
Because it scored close to the top for three themes. That is the intended
multi-theme behavior. Use `--max-themes 1` to disable it.

**Can I preview without creating folders or reports?**
Yes:

```bash
./wallpaper-theme-sort --dry-run
```

**Where do I report bugs or request themes?**
This is a local personal script, so edit it directly. The theme dictionaries and
thresholds are the intended customization points.

---

## Version

- Script version: 1.0
- Documentation updated: 2026-11-07
- Tested with: Python 3, ffmpeg on Linux
