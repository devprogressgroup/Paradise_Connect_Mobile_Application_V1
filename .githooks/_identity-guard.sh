#!/bin/sh
# Logic bersama buat post-commit & post-merge — lihat README di kedua file itu.
if [ -n "$_IDENTITY_HOOK_RUNNING" ]; then
    exit 0
fi

branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
case "$branch" in
    main|Main) ;;
    *) exit 0 ;;
esac

msg=$(git log -1 --format=%B HEAD 2>/dev/null)
case "$msg" in
    *"[allow-identity]"*) exit 0 ;;
esac

prev=$(git rev-parse "HEAD@{1}" 2>/dev/null) || exit 0

protected="android/app/build.gradle.kts android/app/google-services.json ios/Runner/GoogleService-Info.plist firebase.json lib/firebase_options.dart lib/core/network/api_constants.dart"

restored=""
for f in $protected; do
    if git cat-file -e "$prev:$f" 2>/dev/null; then
        if ! git diff --quiet "$prev" HEAD -- "$f" 2>/dev/null; then
            git checkout "$prev" -- "$f"
            restored="$restored $f"
        fi
    fi
done

if [ -n "$restored" ]; then
    git add $restored
    _IDENTITY_HOOK_RUNNING=1 git commit -q -m "chore: restore app identity files on $branch [allow-identity]"
    echo "[identity-guard] Restored identity file(s) on '$branch' via commit baru:$restored"
    echo "[identity-guard] Kalau perubahan ini memang disengaja, commit ulang manual dengan tag [allow-identity]."
fi
