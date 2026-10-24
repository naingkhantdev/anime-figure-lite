"""Rebuild the native splash logo from assets/brand/logo.png.

assets/brand/logo.png is the logo the app shows (square PNG, transparent
where there is no logo, at least 1024x1024). After replacing it, run from
the project folder:

    pip install pillow                      # once
    python tool/brand_assets.py

It writes the native splash logo for Android and iOS at 144dp/pt, which
must match splashLogoSize in lib/ui/widgets/splash_intro.dart.

The launcher icon has its own sources, assets/brand/icon.png (full square)
and icon_foreground.png (Android adaptive layer, transparent);
after changing those run `dart pub global run flutter_launcher_icons`.
"""

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
LOGO = ROOT / "assets/brand/logo.png"
SPLASH_DP = 144


def fit(logo: Image.Image, canvas: int, share: float):
    """The logo centred on a square canvas, its longer side at `share`."""
    out = Image.new("RGBA", (canvas, canvas), (0, 0, 0, 0))
    side = round(canvas * share)
    w, h = logo.size
    scale = side / max(w, h)
    sized = logo.resize((round(w * scale), round(h * scale)), Image.LANCZOS)
    out.alpha_composite(
        sized, ((canvas - sized.width) // 2, (canvas - sized.height) // 2)
    )
    return out


def main():
    logo = Image.open(LOGO).convert("RGBA")
    logo = logo.crop(logo.getchannel("A").getbbox() or (0, 0, *logo.size))

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

    print("Done.")


if __name__ == "__main__":
    main()
