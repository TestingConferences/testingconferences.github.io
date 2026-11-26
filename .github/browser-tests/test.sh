#!/usr/bin/env bash
set -eu

cd "$(dirname "$0")/../.."
if [ ! -f _site/index.html ]; then
  echo "Run bundle exec jekyll build before the browser test." >&2
  exit 1
fi

bundle exec ruby -run -e httpd -- --bind-address=127.0.0.1 --port=4174 _site &
server_pid=$!
trap 'kill "$server_pid" 2>/dev/null || true; wait "$server_pid" 2>/dev/null || true' EXIT

if ! curl --fail --silent --retry 5 --retry-connrefused --max-time 2 \
  http://127.0.0.1:4174/ >/dev/null || ! kill -0 "$server_pid"; then
  echo "Could not start the test site on 127.0.0.1:4174." >&2
  exit 1
fi
VIBIUM_LOAD_AI_ENV=0 node --test .github/browser-tests/conferences.test.mjs
