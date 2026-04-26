#!/bin/bash

# Copy this file to backfill.sh and customize these values.
MIRROR_DIR="/absolute/path/to/The-unseen-work"
WORK_REPO="/absolute/path/to/your-private-work-repo"
WORK_EMAIL="your-work-email@example.com"

if [[ "${1:-}" == "--sample" ]]; then
    cat <<EOF
Sample: what this script does behind the scenes
===============================================

1) Collect already mirrored timestamps from this repo
   git log --format="%s" | grep "sync: work activity on" | sed 's/sync: work activity on //'

2) Read your work-repo commits (oldest -> latest) for:
   - repo:   $WORK_REPO
   - author: $WORK_EMAIL
   git -C "$WORK_REPO" log --reverse --author="$WORK_EMAIL" --format="%ad" --date=format:"%Y-%m-%d %H:%M:%S"

3) For each timestamp not already mirrored:
   - append to activity.log:
       synced: YYYY-MM-DD HH:MM:SS
   - create mirror commit using same timestamp:
       GIT_AUTHOR_DATE="..." GIT_COMMITTER_DATE="..." git commit --allow-empty -m "sync: work activity on ..."

4) Push to origin/main
   git push origin main

Example run output
------------------
[scan] Fetching already mirrored commits...
[scan] Scanning work repo for new commits...
[skip] Already mirrored: 2026-04-22 12:56:08
[sync] Mirroring new commit at 2026-04-24 22:07:43
[push] Pushing to origin/main...
[done] Complete.

Run real sync:
  ./backfill.sh
EOF
    exit 0
fi

cd "$MIRROR_DIR" || exit

echo "🔍 Fetching already mirrored commits..."

# Build a list of already mirrored timestamps from mirror repo.
ALREADY_SYNCED=$(git log --format="%s" | grep "sync: work activity on" | sed 's/sync: work activity on //')

echo "🔍 Scanning work repo for new commits..."

git -C "$WORK_REPO" log \
    --reverse \
    --author="$WORK_EMAIL" \
    --format="%ad" \
    --date=format:"%Y-%m-%d %H:%M:%S" | while read -r commit_date; do

    # Skip if already mirrored.
    if echo "$ALREADY_SYNCED" | grep -qF "$commit_date"; then
        echo "⏭️  Already mirrored: $commit_date — skipping"
        continue
    fi

    echo "📅 Mirroring new commit at $commit_date"
    echo "synced: $commit_date" >> activity.log
    git add activity.log

    GIT_AUTHOR_DATE="$commit_date" \
    GIT_COMMITTER_DATE="$commit_date" \
    git commit --allow-empty -m "sync: work activity on $commit_date"

done

echo "🚀 Pushing..."
git push origin main
echo "✅ Done — no duplicates!"
