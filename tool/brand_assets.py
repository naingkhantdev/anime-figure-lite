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

    assets/brand/logo.png         the badge: the fighter breaking out of a
                                  neon shockwave ring, sparks and glow
                                  behind, on a navy disc; the logo in the app
    assets/brand/poses/NN.png     each pose, the fighter alone, cut out, all
                                  the same apparent size and centred, the
                                  logo's last (splash_intro.dart)
    assets/brand/icon.png         launcher icon: the badge on navy
    assets/brand/icon_foreground.png
                                  Android adaptive icon layer, the badge
                                  over plain navy (pubspec.yaml)
    android .../splash_logo.png, iOS LaunchImage*.png
                                  native splash, 144dp/pt, which must match
                                  splashLogoSize in splash_intro.dart: the
                                  logo's pose exactly as the splash starts
"""

import math
from pathlib import Path

import numpy as np
from PIL import Image, ImageChops, ImageDraw, ImageFilter

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


NEON = (255, 59, 78)   # AppColors.splashNeon


def badge(fighter: Image.Image, disc: bool) -> Image.Image:
    """The app's mark, 1024 square: the fighter breaking out of a glowing
    shockwave ring, a burst of sparks and red light behind him, the splash's
    hit in one picture. With [disc], on a navy disc (transparent outside
    it); without, on nothing, for a layer over navy."""
    n = 1024
    c = n / 2
    out = Image.new("RGBA", (n, n), (0, 0, 0, 0))
    if disc:
        ImageDraw.Draw(out).ellipse((0, 0, n - 1, n - 1), fill=NAVY)

    # Red light behind him, brightest in the middle.
    yy, xx = np.mgrid[0:n, 0:n]
    d = np.hypot(xx - c, yy - c) / (n * 0.46)
    light = np.clip(1 - d, 0, 1) ** 1.6 * 150
    glow = np.zeros((n, n, 4), np.uint8)
    glow[..., :3] = NEON
    glow[..., 3] = light.astype(np.uint8)
    out.alpha_composite(Image.fromarray(glow, "RGBA"))

    # The ring and the sparks, drawn sharp, then laid over a blurred copy
    # of themselves for the neon glow.
    neon = Image.new("RGBA", (n, n), (0, 0, 0, 0))
    draw = ImageDraw.Draw(neon)
    r = n * 0.405
    w = round(n * 0.024)
    draw.ellipse((c - r, c - r, c + r, c + r), outline=NEON + (255,), width=w)
    for i in range(16):
        a = i / 16 * 2 * math.pi + 0.18 * math.sin(i * 7.3)
        inner = n * (0.25 + 0.04 * ((i * 37) % 5) / 4)
        outer = n * (0.36 + 0.07 * ((i * 53) % 7) / 6)
        for k in range(6):   # thick at the root, tapering to a point
            t0, t1 = k / 6, (k + 1) / 6
            p0 = (c + math.cos(a) * (inner + (outer - inner) * t0),
                  c + math.sin(a) * (inner + (outer - inner) * t0))
            p1 = (c + math.cos(a) * (inner + (outer - inner) * t1),
                  c + math.sin(a) * (inner + (outer - inner) * t1))
            draw.line((p0, p1), fill=(255, 190, 195, round(230 * (1 - t0))),
                      width=max(1, round(n * 0.011 * (1 - t0))))
    halo = neon.filter(ImageFilter.GaussianBlur(n * 0.018))
    out.alpha_composite(halo)
    out.alpha_composite(halo)
    out.alpha_composite(neon)

    # Ground glow under his feet.
    ground = Image.new("RGBA", (n, n), (0, 0, 0, 0))
    ImageDraw.Draw(ground).ellipse(
        (c - n * 0.26, n * 0.74, c + n * 0.26, n * 0.80), fill=NEON + (170,))
    out.alpha_composite(ground.filter(ImageFilter.GaussianBlur(n * 0.025)))

    # The fighter, big enough to break out over the ring.
    out.alpha_composite(fit(fighter, n, 0.8))

    if disc:   # keep everything inside the disc
        mask = Image.new("L", (n * 4, n * 4), 0)
        ImageDraw.Draw(mask).ellipse((0, 0, n * 4 - 1, n * 4 - 1), fill=255)
        mask = mask.resize((n, n), Image.LANCZOS)
        out.putalpha(ImageChops.multiply(out.getchannel("A"), mask))
    return out


def main():
    logo_src = SOURCE / "logo.jpg"
    fighter = fighter_cutout(logo_src)
    # The fighter alone, cropped close.
    logo = fighter.crop(fighter.getchannel("A").getbbox())

    # In the app: the badge on its navy disc.
    badge(logo, disc=True).save(BRAND / "logo.png", optimize=True)

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

    # Launcher icons must be solid: the badge on the splash navy. Adaptive
    # Android masks to a circle or squircle, so there the badge is its own
    # layer inside the safe zone, over plain navy (pubspec.yaml).
    mark = badge(logo, disc=False)
    icon = Image.new("RGBA", (1024, 1024), NAVY)
    icon.alpha_composite(fit(mark, 1024, 0.98))
    icon.convert("RGB").save(BRAND / "icon.png", optimize=True)
    # 75%: the ring stays inside the part of an adaptive icon no launcher
    # mask cuts into; only the outer glow may be trimmed.
    fit(mark, 1024, 0.75).save(BRAND / "icon_foreground.png", optimize=True)

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
