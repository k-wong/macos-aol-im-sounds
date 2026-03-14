#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
REQUIRED_MP3S=("exit.mp3" "open.mp3" "message.mp3")
DMG_PATH="$ROOT_DIR/dist/macos-soundboard-unsigned.dmg"
SUCCEEDED=0

pause() {
    printf '\nPress Return to close...'
    read -r
}

finish() {
    local exit_code=$?

    if (( exit_code == 0 )) && (( SUCCEEDED == 1 )); then
        if [[ -f "$DMG_PATH" ]]; then
            printf '\nFinished. Your unsigned DMG is at:\n%s\n' "$DMG_PATH"
            open -R "$DMG_PATH"
        fi
    else
        printf '\nBuild failed before the DMG was created.\n'
        printf 'If a Terminal window is open above this message, the error details are there.\n'
    fi

    pause
    exit "$exit_code"
}

trap finish EXIT

cd "$ROOT_DIR"

printf 'Checking for required MP3 files in %s\n\n' "$ROOT_DIR"

missing_files=()
for filename in "${REQUIRED_MP3S[@]}"; do
    if [[ -s "$ROOT_DIR/$filename" ]]; then
        printf '  [ok] %s\n' "$filename"
    else
        printf '  [missing] %s\n' "$filename"
        missing_files+=("$filename")
    fi
done

if (( ${#missing_files[@]} > 0 )); then
    printf '\nAdd your own MP3 files with those exact names, then run this again.\n'
    pause
    exit 1
fi

printf '\nBuilding unsigned DMG...\n\n'
"$ROOT_DIR/scripts/package_unsigned_dmg.sh"
SUCCEEDED=1
