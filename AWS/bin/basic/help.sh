#!/bin/bash

HELP_FOLDER="$(cd "$LITTLE_HOME/../Notes/Areas/reference/cli" && pwd)"
README="$HELP_FOLDER/README.md"
detail="$1"
PAGER="${PAGER:-less}"

open() {
  local filePath="$1"
  cat - "$filePath" <<< "$filePath" | $PAGER
}
if [[ -z "$detail" ]]; then
  open "$README"
  exit $?
fi

# Try to find an exact match for the given command
filePath="$(find "$HELP_FOLDER" -name "${detail}.md" -print | head -1)"
if [[ -n "$filePath" ]]; then
  open "$filePath"
  exit $?
fi

# Try to help the user find what she wants
echo "Could not find ${detail}.md under $HELP_FOLDER"
echo --------------
echo grep "$README"
grep "$detail" "$README"
