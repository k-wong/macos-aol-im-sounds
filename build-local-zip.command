#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
ZIP_PATH="$ROOT_DIR/dist/macos-soundboard-unsigned.zip"
SUCCEEDED=0

pause() {
    printf '\nPress Return to close...'
    read -r
}

finish() {
    local exit_code=$?

    if (( exit_code == 0 )) && (( SUCCEEDED == 1 )); then
        if [[ -f "$ZIP_PATH" ]]; then
            printf '\nFinished. Your unsigned zip is at:\n%s\n' "$ZIP_PATH"
            open -R "$ZIP_PATH"
        fi
    else
        printf '\nBuild failed before the zip was created.\n'
        printf 'If a Terminal window is open above this message, the error details are there.\n'
    fi

    pause
    exit "$exit_code"
}

trap finish EXIT

cd "$ROOT_DIR"
printf 'Building unsigned zip from %s...\n\n' "$ROOT_DIR"
"$ROOT_DIR/scripts/package_unsigned_zip.sh"
SUCCEEDED=1
