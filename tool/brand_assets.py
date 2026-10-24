"""Rebuild every logo image from assets/brand/logo.png.

Put your logo at assets/brand/logo.png (square PNG, transparent background,
at least 1024x1024), then from the project folder run:

    pip install pillow                      # once
    python tool/brand_assets.py
    dart pub global run flutter_launcher_icons

It writes:
  - the native splash logo for Android and iOS, 144dp/pt (must match
    splashLogoSize in lib/ui/widgets/splash_intro.dart)
  - assets/brand/app_icon.png and app_icon_foreground.png, the sources
    flutter_launcher_icons turns into the launcher icons
"""

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
LOGO = ROOT / "assets/brand/logo.png"
SPLASH_DP = 144
BACKGROUND = (255, 255, 255, 255)  # AppColors.surface


def fit(logo: Image.Image, canvas: int, share: float, bg=(0, 0, 0, 0)):
    """The logo centred on a square canvas, its longer side at `share`."""
    out = Image.new("RGBA", (canvas, canvas), bg)
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

    brand = ROOT / "assets/brand"
    # Full icon (iOS, old Android): logo on white with breathing room.
    fit(logo, 1024, 0.62, BACKGROUND).convert("RGB").save(
        brand / "app_icon.png", optimize=True)
    # Android adaptive foreground: the launcher crops to a circle or squircle,
    # so keep the logo well inside the safe zone.
    fit(logo, 1024, 0.72).save(brand / "app_icon_foreground.png",
                               optimize=True)
    print("Done. Now run: dart pub global run flutter_launcher_icons")


if __name__ == "__main__":
    main()
