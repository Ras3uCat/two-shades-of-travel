#!/usr/bin/env bash
# PostToolUse hook — enforce 300-line Dart file limit
# Blocks Write/Edit if a lib/ Dart file exceeds 300 lines

INPUT=$(cat)

FILE=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('tool_input', {}).get('file_path', ''))
except:
    print('')
" 2>/dev/null)

# Only check Dart files inside lib/ (any depth)
if [[ "$FILE" != */lib/**/*.dart && "$FILE" != */lib/*.dart ]]; then
  exit 0
fi

if [ ! -f "$FILE" ]; then
  exit 0
fi

LINE_COUNT=$(wc -l < "$FILE")

if [ "$LINE_COUNT" -gt 300 ]; then
  echo "{\"continue\": false, \"stopReason\": \"File size violation: $FILE has $LINE_COUNT lines (limit: 300). Extract to sub-files per flutter_style.md conventions (_prefix for private widgets).\"}"
  exit 0
fi

echo '{"continue": true}'
exit 0
