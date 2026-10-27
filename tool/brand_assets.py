"""Build every logo image the app uses from the source art.

Source art (square images of the red neon fighter on its glass tile, on the
dark background, as made by the artist):

    assets/brand/source/logo.jpg        the logo: the pose the app rests on
    assets/brand/source/poses/*.jpg|png more fighting poses, same tile and
                                        style; the splash plays them in
                                        name order (1.jpg, 2.jpg, ...), then
                                        lands on the logo

After changing any of them, run from the project folder:

    pip install pillow                           # once
    python tool/brand_assets.py
    dart pub global run flutter_launcher_icons   # launcher icon

It writes:

    assets/brand/logo.png         the glowing fighter alone, transparent
                                  around it; the logo everywhere in the app
    assets/brand/poses/NN.png     each pose cut out the same way, then the
                                  logo's last (splash_intro.dart)
    assets/brand/icon.png         launcher icon: the fighter on navy
    assets/brand/icon_foreground.png
                                  Android adaptive icon layer, over plain
                                  navy (pubspec.yaml)
    android .../splash_logo.png, iOS LaunchImage*.png
                                  native splash, 144dp/pt, which must match
                                  splashLogoSize in splash_intro.dart
"""

from pathlib import Path

from PIL import Image, ImageChops, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
BRAND = ROOT / "assets/brand"
SOURCE = BRAND / "source"
SPLASH_DP = 144
POSE_PX = 512          # splash draws 144dp; 3.5x covers the sharpest phones
POSE_MARGIN = 0.06     # tile rim left out of the splash poses, each side
NAVY = (18, 24, 44, 255)  # AppColors.splash


def find_tile(img: Image.Image):
    """The glass tile's box: where a row and a column through it turn
    clearly lighter than the background."""
    px = img.convert("L").load()
    w, h = img.size

    def span(values):
        base = values[len(values) // 50]
        lit = [i for i, v in enumerate(values) if v > base + 20]
        return lit[0], lit[-1] + 1

    x0, x1 = span([px[x, h * 3 // 10] for x in range(w)])
    y0, y1 = span([px[w * 3 // 10, y] for y in range(h)])
    side = max(x1 - x0, y1 - y0)
    return (x0, y0, x0 + side, y0 + side)



def tile_of(path: Path, size: int) -> Image.Image:
    img = Image.open(path).convert("RGB")
    return img.crop(find_tile(img)).resize((size, size), Image.LANCZOS)


def fighter_cutout(tile: Image.Image) -> Image.Image:
    """Just the red neon fighter, transparent elsewhere: alpha is how much
    redder than grey each pixel is, so the glow fades out softly.

    A glowing pixel is part fighter, part grey glass behind it. The glass
    is estimated (the tile with the red taken out, blurred) and taken back
    out of each pixel's colour, so on a light background the glow is red
    light, not a grey haze."""
    rgb = tile.convert("RGB")
    r, g, b = rgb.split()
    redness = ImageChops.subtract(r, ImageChops.lighter(g, b))
    alpha = redness.point(lambda v: max(0, min(255, (v - 8) * 6)))

    glass = Image.merge("RGB", (ImageChops.darker(r, ImageChops.lighter(g, b)),
                                g, b)).filter(ImageFilter.GaussianBlur(24))
    px, bg, a = rgb.load(), glass.load(), alpha.load()
    out = Image.new("RGBA", rgb.size)
    o = out.load()
    for y in range(rgb.height):
        for x in range(rgb.width):
            k = a[x, y]
            if k == 0:
                continue
            f = k / 255
            # pixel = f * fighter + (1 - f) * glass, solved for fighter
            o[x, y] = tuple(
                max(0, min(255, round((c - (1 - f) * q) / f)))
                for c, q in zip(px[x, y], bg[x, y])) + (k,)
    return out


def pose_frame(cutout: Image.Image) -> Image.Image:
    """The middle of a tile, where the fighter is, the same box for every
    pose: the tile's rim and corners stay out."""
    n = cutout.width
    m = round(n * POSE_MARGIN)
    return cutout.crop((m, m, n - m, n - m))


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
    fighter = fighter_cutout(tile_of(logo_src, 1024))

    # In the app: the fighter alone, transparent around it, cropped close.
    logo = fighter.crop(fighter.getchannel("A").getbbox())
    fit(logo, 1024, 1.0).save(BRAND / "logo.png", optimize=True)

    # The splash's poses: the extra ones in name order, the logo last. All
    # cut from the same part of their tile, so a pose change doesn't jump.
    out = BRAND / "poses"
    out.mkdir(exist_ok=True)
    for old in out.glob("*.png"):
        old.unlink()
    extra = sorted(p for p in (SOURCE / "poses").glob("*")
                   if p.suffix.lower() in (".jpg", ".jpeg", ".png"))
    for i, path in enumerate([*extra, logo_src]):
        pose_frame(fighter_cutout(tile_of(path, 1024))).resize(
            (POSE_PX, POSE_PX), Image.LANCZOS).save(
                out / f"{i:02d}.png", optimize=True)

    # Launcher icons must be solid: the fighter on the splash navy. Adaptive
    # Android masks to a circle or squircle, so there the fighter is its own
    # layer inside the safe zone, over plain navy (pubspec.yaml).
    icon = Image.new("RGBA", (1024, 1024), NAVY)
    icon.alpha_composite(fit(logo, 1024, 0.78))
    icon.convert("RGB").save(BRAND / "icon.png", optimize=True)
    # 66%: the part of an adaptive icon no launcher mask cuts into.
    fit(logo, 1024, 0.66).save(BRAND / "icon_foreground.png", optimize=True)

    # Native splash: the same picture as the splash's first frame, the
    # logo's pose as cut for the poses.
    splash = pose_frame(fighter)
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

    print(f"Done: logo, {len(extra) + 1} splash pose(s), icons, splash logos.")


if __name__ == "__main__":
    main()
