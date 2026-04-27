#!/bin/bash
# Octave decoder for toml-test.
# Reads TOML from stdin, writes JSON to stdout, exits 1 on parse error.

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmpfile=$(mktemp /tmp/toml_XXXXXX.toml)
errfile=$(mktemp /tmp/toml_XXXXXX.err)
cat > "$tmpfile"

use_dict="${TOML_USE_DICT:-0}"

octave-cli --norc --eval "
  addpath('$REPO_DIR');
  addpath('$REPO_DIR/test');
  addpath('$REPO_DIR/+toml/private');
  try
    if $use_dict
      result = toml.read('$tmpfile', 'UseDictionary', true);
    else
      result = toml.read('$tmpfile');
    end
    fprintf('%s\n', toml.testing.jsonify(result));
  catch e
    fid = fopen('$errfile', 'w');
    fprintf(fid, '%s\n', e.message);
    fclose(fid);
  end
" 2>/dev/null

status=0
if [ -s "$errfile" ]; then
  cat "$errfile" >&2
  status=1
fi

rm -f "$tmpfile" "$errfile"
exit $status
