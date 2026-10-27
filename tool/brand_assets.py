"""Build every logo image the app uses from the source art.

Source art: square images of the red neon fighter on a dark background,
with or without a glass tile behind it (the script keeps only the fighter):

    assets/brand/source/logo.jpg        the logo: the pose the app rests on
    assets/brand/source/poses/*.jpg|png more fighting poses in the same
                                        style; the splash plays them in
                                        name order (1.jpg, 2.jpg, ...), then
                                        lands on the logo

After changing any of them, run from the project folder:

    pip install pillow numpy                     # once
    python tool/brand_assets.py
    dart pub global run flutter_launcher_icons   # launcher icon

It writes:

    assets/brand/logo.png         the glowing fighter alone, transparent
                                  around it; the logo everywhere in the app
    assets/brand/poses/NN.png     each pose cut out the same way, all the
                                  same apparent size and centred, the
                                  logo's last (splash_intro.dart)
    assets/brand/icon.png         launcher icon: the fighter on navy
    assets/brand/icon_foreground.png
                                  Android adaptive icon layer, over plain
                                  navy (pubspec.yaml)
    android .../splash_logo.png, iOS LaunchImage*.png
                                  native splash, 144dp/pt, which must match
                                  splashLogoSize in splash_intro.dart: the
                                  logo's pose exactly as the splash starts
"""

from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
BRAND = ROOT / "assets/brand"
SOURCE = BRAND / "source"
SPLASH_DP = 144
WORK = 1024            # every source is handled at this size
POSE_PX = 512          # splash draws 144dp; 3.5x covers the sharpest phones
POSE_FILL = 0.84       # the logo's pose: its longer side, share of the frame
NAVY = (18, 24, 44, 255)  # AppColors.splash


def fighter_cutout(path: Path) -> Image.Image:
    """Just the red neon fighter from [path], transparent elsewhere.

    Alpha is how much redder than grey each pixel is, so the glow fades out
    softly. A glowing pixel is part fighter, part whatever is behind it
    (navy, black or a glass tile); that background is estimated (the image
    with the red taken out, blurred) and taken back out of the colour, so
    on a light screen the glow is red light, not a grey haze. Red that
    isn't the fighter, such as a tile's glowing edge, is dropped."""
    img = Image.open(path).convert("RGB").resize((WORK, WORK), Image.LANCZOS)
    px = np.asarray(img).astype(np.float32)
    r, g, b = px[..., 0], px[..., 1], px[..., 2]
    grey = np.maximum(g, b)
    redness = r - grey
    # Some glass is tinted red all over; start above its tint, so only the
    # fighter's much redder glow counts.
    tint = redness[(redness >= 4) & (redness <= 40)]
    floor = (np.percentile(tint, 90) + 4
             if tint.size > 0.15 * redness.size else 8)
    alpha = np.clip((redness - floor) * 6, 0, 255)
    # Only what is inside a tile, if there is one: its edge may glow red.
    # Its edge fades in over a few pixels, so a glow cut there trails off.
    x0, y0, x1, y1 = _inside_tile(px)
    inside = Image.new("L", (WORK, WORK), 0)
    inside.paste(255, (x0, y0, x1, y1))
    alpha *= np.asarray(inside.filter(ImageFilter.GaussianBlur(10))) / 255
    alpha *= _fighter_mask(alpha)

    unred = px.copy()
    unred[..., 0] = np.minimum(r, grey)
    behind = np.asarray(Image.fromarray(unred.astype(np.uint8)).filter(
        ImageFilter.GaussianBlur(24))).astype(np.float32)

    f = (alpha / 255)[..., None]
    with np.errstate(divide="ignore", invalid="ignore"):
        colour = np.where(f > 0, (px - (1 - f) * behind) / f, 0)
    out = np.dstack([np.clip(colour, 0, 255), alpha]).astype(np.uint8)
    return Image.fromarray(out, "RGBA")


def _inside_tile(px: np.ndarray):
    """The box inside a glass tile behind the fighter, short of its edge;
    the whole picture when there is no tile. A tile is a big solid square
    that differs from the background in the corners: most of each row and
    column across it does."""
    n = px.shape[0]
    corners = np.concatenate([px[:24, :24], px[:24, -24:],
                              px[-24:, :24], px[-24:, -24:]]).reshape(-1, 3)
    differs = np.abs(px - corners.mean(axis=0)).sum(axis=2) > 45
    # Some glass is shaded nearly to the background on one side, so a third
    # of a row is enough, and a few rows may fall short.
    rows = np.nonzero(differs.mean(axis=1) > 0.35)[0]
    cols = np.nonzero(differs.mean(axis=0) > 0.35)[0]
    if (rows.size < 0.4 * n or cols.size < 0.4 * n
            or rows[-1] - rows[0] > 1.6 * rows.size
            or cols[-1] - cols[0] > 1.6 * cols.size):
        return 0, 0, n, n  # no solid square: no tile
    x0, y0, x1, y1 = cols[0], rows[0], cols[-1] + 1, rows[-1] + 1
    # Stay clear of the edge; further when the edge itself glows red.
    ring = round(0.05 * n)
    redness = px[..., 0] - np.maximum(px[..., 1], px[..., 2])
    edge = np.concatenate([
        redness[y0:y0 + ring, x0:x1].ravel(), redness[y1 - ring:y1, x0:x1].ravel(),
        redness[y0:y1, x0:x0 + ring].ravel(), redness[y0:y1, x1 - ring:x1].ravel()])
    inset = round((0.08 if np.median(edge) > 25 else 0.035) * n)
    return x0 + inset, y0 + inset, x1 - inset, y1 - inset


def _fighter_mask(alpha: np.ndarray) -> np.ndarray:
    """1 over the fighter and its glow, 0 elsewhere: the big glowing shapes
    in the middle, not thin ones that frame the picture (a tile's edge)."""
    n = 256
    small = np.asarray(Image.fromarray(alpha.astype(np.uint8)).resize(
        (n, n), Image.BOX).filter(ImageFilter.MaxFilter(5))) > 30
    labels = np.zeros((n, n), np.int32)
    parts = []
    for y, x in zip(*np.nonzero(small)):
        if labels[y, x]:
            continue
        label = len(parts) + 1
        labels[y, x] = label
        stack, cells = [(y, x)], []
        while stack:
            cy, cx = stack.pop()
            cells.append((cy, cx))
            for ny, nx in ((cy + 1, cx), (cy - 1, cx), (cy, cx + 1), (cy, cx - 1)):
                if 0 <= ny < n and 0 <= nx < n and small[ny, nx] \
                        and not labels[ny, nx]:
                    labels[ny, nx] = label
                    stack.append((ny, nx))
        ys, xs = zip(*cells)
        frames = (max(xs) - min(xs) > 0.85 * n and max(ys) - min(ys) > 0.85 * n
                  and len(cells) < 0.25 * n * n)
        parts.append((label, len(cells), frames))
    biggest = max((size for _, size, frames in parts if not frames), default=0)
    keep = [label for label, size, frames in parts
            if not frames and size >= 0.08 * biggest]
    mask = np.isin(labels, keep).astype(np.uint8) * 255
    grown = Image.fromarray(mask).filter(ImageFilter.MaxFilter(9)).resize(
        (WORK, WORK), Image.BILINEAR).filter(ImageFilter.GaussianBlur(6))
    return np.asarray(grown).astype(np.float32) / 255


def ink(cutout: Image.Image) -> float:
    """How much glowing fighter there is: the same for two poses means they
    look the same size, however differently they are spread out."""
    return float(np.asarray(cutout.getchannel("A")).astype(np.float64).sum())


def frame_pose(cutout: Image.Image, scale: float) -> Image.Image:
    """[cutout] at [scale], centred on a transparent WORK square, shrunk if
    it would not fit."""
    fighter = cutout.crop(cutout.getchannel("A").getbbox())
    scale = min(scale, 0.96 * WORK / max(fighter.size))
    sized = fighter.resize((max(1, round(fighter.width * scale)),
                            max(1, round(fighter.height * scale))),
                           Image.LANCZOS)
    out = Image.new("RGBA", (WORK, WORK), (0, 0, 0, 0))
    out.alpha_composite(
        sized, ((WORK - sized.width) // 2, (WORK - sized.height) // 2))
    return out


def fit(img: Image.Image, canvas: int, share: float) -> Image.Image:
    """[img] centred on a transparent square, its longer side at [share]."""
    out = Image.new("RGBA", (canvas, canvas), (0, 0, 0, 0))
    side = round(canvas * share)
    scale = side / max(img.size)
    sized = img.resize(
        (round(img.width * scale), round(img.height * scale)), Image.LANCZOS)
    out.alpha_composite(
        sized, ((canvas - sized.width) // 2, (canvas - sized.height) // 2))
    return out


def main():
    logo_src = SOURCE / "logo.jpg"
    fighter = fighter_cutout(logo_src)

    # In the app: the fighter alone, transparent around it, cropped close.
    logo = fighter.crop(fighter.getchannel("A").getbbox())
    fit(logo, 1024, 1.0).save(BRAND / "logo.png", optimize=True)

    # The splash's poses: the extra ones in name order, the logo's last.
    # The logo's pose fills POSE_FILL of the frame; every other pose gets
    # the same amount of glow, so the fighter keeps its size between poses.
    logo_scale = POSE_FILL * WORK / max(logo.size)
    target = ink(fighter) * logo_scale ** 2
    extra = sorted(p for p in (SOURCE / "poses").glob("*")
                   if p.suffix.lower() in (".jpg", ".jpeg", ".png"))
    frames = []
    for path in extra:
        cut = fighter_cutout(path)
        frames.append(frame_pose(cut, (target / ink(cut)) ** 0.5))
    frames.append(frame_pose(fighter, logo_scale))

    out = BRAND / "poses"
    out.mkdir(exist_ok=True)
    for old in out.glob("*.png"):
        old.unlink()
    for i, frame in enumerate(frames):
        frame.resize((POSE_PX, POSE_PX), Image.LANCZOS).save(
            out / f"{i:02d}.png", optimize=True)

    # Launcher icons must be solid: the fighter on the splash navy. Adaptive
    # Android masks to a circle or squircle, so there the fighter is its own
    # layer inside the safe zone, over plain navy (pubspec.yaml).
    icon = Image.new("RGBA", (1024, 1024), NAVY)
    icon.alpha_composite(fit(logo, 1024, 0.78))
    icon.convert("RGB").save(BRAND / "icon.png", optimize=True)
    # 66%: the part of an adaptive icon no launcher mask cuts into.
    fit(logo, 1024, 0.66).save(BRAND / "icon_foreground.png", optimize=True)

    # Native splash: exactly the splash's first frame, the logo's pose.
    splash = frames[-1]
    res = ROOT / "android/app/src/main/res"
    for folder, mult in [("mdpi", 1), ("hdpi", 1.5), ("xhdpi", 2),
                         ("xxhdpi", 3), ("xxxhdpi", 4)]:
        n = round(SPLASH_DP * mult)
        splash.resize((n, n), Image.LANCZOS).save(
            res / f"drawable-{folder}/splash_logo.png", optimize=True)

    ios = ROOT / "ios/Runner/Assets.xcassets/LaunchImage.imageset"
    for suffix, mult in [("", 1), ("@2x", 2), ("@3x", 3)]:
        n = SPLASH_DP * mult
        splash.resize((n, n), Image.LANCZOS).save(
            ios / f"LaunchImage{suffix}.png", optimize=True)

    print(f"Done: logo, {len(frames)} splash poses, icons, splash logos.")


if __name__ == "__main__":
    main()
