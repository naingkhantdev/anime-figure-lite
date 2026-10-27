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

    assets/brand/logo.png         the tile, rounded, transparent outside;
                                  the logo everywhere in the app
    assets/brand/poses/NN.png     each pose as a tile like logo.png, then
                                  the logo last (splash_intro.dart)
    assets/brand/icon.png         launcher icon, full square
    assets/brand/icon_foreground.png, icon_background.png
                                  Android adaptive icon: the glowing fighter
                                  cut out, over the tile softly blurred
    android .../splash_logo.png, iOS LaunchImage*.png
                                  native splash, 144dp/pt, which must match
                                  splashLogoSize in splash_intro.dart
"""

from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
BRAND = ROOT / "assets/brand"
SOURCE = BRAND / "source"
SPLASH_DP = 144
POSE_PX = 512          # splash draws 144dp; 3.5x covers the sharpest phones
CORNER = 0.165         # the tile's corner radius, as a share of its side


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


def rounded(tile: Image.Image) -> Image.Image:
    """The tile with its own rounded corners, transparent outside them.
    The mask is drawn 4x and scaled down, so the edge is smooth."""
    n = tile.width
    big = Image.new("L", (n * 4, n * 4), 0)
    ImageDraw.Draw(big).rounded_rectangle(
        (0, 0, n * 4 - 1, n * 4 - 1), radius=round(n * 4 * CORNER), fill=255)
    out = tile.convert("RGBA")
    out.putalpha(big.resize((n, n), Image.LANCZOS))
    return out


def tile_of(path: Path, size: int) -> Image.Image:
    img = Image.open(path).convert("RGB")
    return img.crop(find_tile(img)).resize((size, size), Image.LANCZOS)


def fighter_cutout(tile: Image.Image) -> Image.Image:
    """Just the red neon fighter, transparent elsewhere: alpha is how much
    redder than grey each pixel is, so the glow fades out softly."""
    r, g, b = tile.convert("RGB").split()
    redness = ImageChops.subtract(r, ImageChops.lighter(g, b))
    alpha = redness.point(lambda v: max(0, min(255, (v - 8) * 6)))
    out = tile.convert("RGBA")
    out.putalpha(alpha)
    return out


def without_fighter(tile: Image.Image) -> Image.Image:
    """The tile's glass with the red taken out, for a backdrop that has no
    second, blurred fighter in it."""
    r, g, b = tile.convert("RGB").split()
    grey = ImageChops.add(ImageChops.lighter(g, b), Image.new("L", r.size, 6))
    return Image.merge("RGB", (ImageChops.darker(r, grey), g, b))


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
    tile = tile_of(logo_src, 1024)

    logo = rounded(tile)
    logo.save(BRAND / "logo.png", optimize=True)

    # The splash's poses: the extra ones in name order, the logo last.
    out = BRAND / "poses"
    out.mkdir(exist_ok=True)
    for old in out.glob("*.png"):
        old.unlink()
    extra = sorted(p for p in (SOURCE / "poses").glob("*")
                   if p.suffix.lower() in (".jpg", ".jpeg", ".png"))
    for i, path in enumerate([*extra, logo_src]):
        rounded(tile_of(path, POSE_PX)).save(out / f"{i:02d}.png", optimize=True)

    # Launcher: iOS and older Android show the whole tile; adaptive Android
    # masks it to a circle or squircle, so the fighter goes on its own
    # layer inside the safe zone, over the tile blurred into a soft glow.
    tile.save(BRAND / "icon.png", optimize=True)
    fighter = fighter_cutout(tile)
    fighter = fighter.crop(fighter.getchannel("A").getbbox())
    # 66%: the part of an adaptive icon no launcher mask cuts into.
    fit(fighter, 1024, 0.66).save(BRAND / "icon_foreground.png", optimize=True)
    without_fighter(tile).filter(ImageFilter.GaussianBlur(48)).save(
        BRAND / "icon_background.png", optimize=True)

    res = ROOT / "android/app/src/main/res"
    for folder, mult in [("mdpi", 1), ("hdpi", 1.5), ("xhdpi", 2),
                         ("xxhdpi", 3), ("xxxhdpi", 4)]:
        n = round(SPLASH_DP * mult)
        fit(logo, n, 1.0).save(res / f"drawable-{folder}/splash_logo.png",
                               optimize=True)

    ios = ROOT / "ios/Runner/Assets.xcassets/LaunchImage.imageset"
    for suffix, mult in [("", 1), ("@2x", 2), ("@3x", 3)]:
        n = SPLASH_DP * mult
        fit(logo, n, 1.0).save(ios / f"LaunchImage{suffix}.png", optimize=True)

    print(f"Done: logo, {len(extra) + 1} splash pose(s), icons, splash logos.")


if __name__ == "__main__":
    main()
