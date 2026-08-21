#!/usr/bin/env bash
set -euo pipefail

before="${1:?informe o commit antes do push}"
after="${2:?informe o commit depois do push}"

if [[ "$before" =~ ^0+$ ]]; then
  range="$after"
else
  range="$before..$after"
fi

pattern='^(feat|fix|docs|style|refactor|perf|test|build|ci|chore)(\([a-z0-9_-]+\))?: .+$'
status=0

while IFS= read -r sha; do
  subject=$(git log -1 --format=%s "$sha")
  body=$(git log -1 --format=%b "$sha")
  full=$(git log -1 --format=%B "$sha")

  if ! [[ "$subject" =~ $pattern ]]; then
    echo "commit $sha: título não segue Conventional Commits: $subject" >&2
    status=1
  fi

  if [[ -n "$(echo "$body" | tr -d '[:space:]')" ]]; then
    echo "commit $sha: tem corpo, deveria ser só o título: $subject" >&2
    status=1
  fi

  if echo "$full" | grep -qi "co-authored-by"; then
    echo "commit $sha: tem trailer Co-Authored-By, não permitido: $subject" >&2
    status=1
  fi
done < <(git rev-list "$range")

exit "$status"
