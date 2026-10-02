#!/bin/bash
# Pulls the latest skills from the original repo (coreyhaines31/marketingskills)
# at the start of every cloud session, so skills are up to date before use.
# Never fails the session: any problem is reported and the local copy is kept.
set -uo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

UPSTREAM_URL="https://github.com/coreyhaines31/marketingskills"
cd "${CLAUDE_PROJECT_DIR:-$(dirname "$0")/../..}" || exit 0

if ! git remote get-url upstream >/dev/null 2>&1; then
  git remote add upstream "$UPSTREAM_URL"
fi

if ! timeout 60 git fetch --quiet upstream main 2>/dev/null; then
  echo "Skills update check: could not reach $UPSTREAM_URL. Using local skills as they are."
  exit 0
fi

behind=$(git rev-list --count HEAD..upstream/main)
if [ "$behind" -eq 0 ]; then
  echo "Skills update check: skills are up to date with upstream."
  exit 0
fi

if [ -n "$(git status --porcelain)" ]; then
  echo "Skills update check: $behind upstream update(s) available, but the working tree has uncommitted changes, so they were not applied."
  exit 0
fi

changed=$(git diff --name-only HEAD...upstream/main -- skills | cut -d/ -f2 | sort -u | tr '\n' ' ')

git_id=()
git config user.name >/dev/null || git_id+=(-c user.name="Skills Sync")
git config user.email >/dev/null || git_id+=(-c user.email="skills-sync@localhost")

if git "${git_id[@]}" merge --quiet --no-edit upstream/main >/dev/null 2>&1; then
  echo "Skills update check: applied $behind update(s) from upstream."
  [ -n "$changed" ] && echo "Updated skills: $changed"
else
  git merge --abort >/dev/null 2>&1
  echo "Skills update check: $behind upstream update(s) available, but they conflict with local changes and were not applied."
fi
exit 0
