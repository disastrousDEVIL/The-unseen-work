#!/bin/bash
set -euo pipefail

# Copy this file to backfill.sh and customize these values.
MIRROR_DIR="/absolute/path/to/The-unseen-work"
WORK_REPO="/absolute/path/to/your-private-work-repo"
WORK_NAME="Your Name"
WORK_EMAIL="your-work-email@example.com"
MIRROR_NAME="Your Name"
MIRROR_EMAIL="your-personal-email@example.com"

if [[ "${1:-}" == "--sample" ]]; then
    cat <<EOF
Sample: what this script does behind the scenes
===============================================

1) Collect already mirrored timestamps from this repo for:
   - mirror email: $MIRROR_EMAIL
   git log --format="%ae%x09%s" | awk -v email="$MIRROR_EMAIL" -F '\t' '\$1 == email { sub(/^sync: work activity on /, "", \$2); print \$2 }'

2) Read your work-repo commits (oldest -> latest) for:
   - repo:   $WORK_REPO
   - name:   $WORK_NAME
   - email:  $WORK_EMAIL
   git -C "$WORK_REPO" log --reverse --author="$WORK_EMAIL" --format="%ad" --date=format:"%Y-%m-%d %H:%M:%S"

3) For each timestamp not already mirrored:
   - append to activity.log:
       synced: YYYY-MM-DD HH:MM:SS
   - create mirror commit using same timestamp and mirror identity:
       GIT_AUTHOR_DATE="..." GIT_COMMITTER_DATE="..." git commit --allow-empty -m "sync: work activity on ..."

4) Push to origin/main
   git push origin main

Example run output
------------------
🔍 Fetching already mirrored commits...
🔍 Scanning work repo for new commits...
⏭️  Already mirrored: 2026-04-22 12:56:08 — skipping
📅 Mirroring new commit at 2026-04-24 22:07:43
🚀 Pushing...
✅ Done — no duplicates!

Run real sync:
  ./backfill.sh
EOF
    exit 0
fi

cd "$MIRROR_DIR" || exit

echo "🔍 Fetching already mirrored commits..."

# Build a list of timestamps already mirrored with the desired mirror email.
ALREADY_SYNCED=$(git log --format="%ae%x09%s" | awk -v email="$MIRROR_EMAIL" -F '\t' '$1 == email { sub(/^sync: work activity on /, "", $2); print $2 }')

echo "🔍 Scanning work repo for new commits..."

while read -r commit_date; do
    [[ -n "$commit_date" ]] || continue

    # Skip if already mirrored
    if echo "$ALREADY_SYNCED" | grep -qF "$commit_date"; then
        echo "⏭️  Already mirrored: $commit_date — skipping"
        continue
    fi

    echo "📅 Mirroring new commit at $commit_date"
    echo "synced: $commit_date" >> activity.log
    git add activity.log

    GIT_AUTHOR_DATE="$commit_date" \
    GIT_COMMITTER_DATE="$commit_date" \
    GIT_AUTHOR_NAME="$MIRROR_NAME" \
    GIT_AUTHOR_EMAIL="$MIRROR_EMAIL" \
    GIT_COMMITTER_NAME="$MIRROR_NAME" \
    GIT_COMMITTER_EMAIL="$MIRROR_EMAIL" \
    git commit --allow-empty -m "sync: work activity on $commit_date"

done < <(
    git -C "$WORK_REPO" log \
        --reverse \
        --author="$WORK_EMAIL" \
        --format="%ad" \
        --date=format:"%Y-%m-%d %H:%M:%S" | sort -u
)

echo "🚀 Pushing..."
git push origin main
echo "✅ Done — no duplicates!"
