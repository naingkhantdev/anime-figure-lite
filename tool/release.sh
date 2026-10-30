#!/usr/bin/env bash
# Builds the release APK and publishes it on GitHub, where the download page
# (public/index.html) and the in-app update check (app_config/android) point.
# See README "Releasing an update".
#
#   tool/release.sh "What changed, for the release notes"
#
# Needs the GitHub CLI (gh), signed in to an account that can write to
# $REPO. Bump `version:` in pubspec.yaml first: the number after the + must
# go up every release.
set -euo pipefail
cd "$(dirname "$0")/.."

# Public, holds only the APKs; the code stays private.
REPO=naingkhantdev/anime-figure-lite-releases

version=$(grep -m1 '^version:' pubspec.yaml | sed 's/^version: *//')
name=${version%%+*}
build=${version##*+}

if [ ! -f android/key.properties ]; then
  echo "android/key.properties is missing: the APK must be signed with the" >&2
  echo "same key every time, or it won't install over the old app." >&2
  exit 1
fi

flutter build apk --release
# The same file name every release, so .../releases/latest/download/app.apk
# always gets the newest.
cp build/app/outputs/flutter-apk/app-release.apk build/app.apk

gh release create "v$name-$build" build/app.apk \
  --repo "$REPO" --title "$name ($build)" --notes "${1:-}"

cat <<EOF

Released $name ($build). Now, in Firebase console -> Firestore ->
app_config/android, set:
  latest_version  $build
  min_version     (unchanged, or $build if older builds must stop working)
  apk_url         https://github.com/$REPO/releases/latest/download/app.apk
EOF
