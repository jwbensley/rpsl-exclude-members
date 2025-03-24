#!/bin/bash

set -e

WATCH_FILE="$1"
HTTP_DIR="$(dirname "$WATCH_FILE")/"
if [ -z "$WATCH_FILE" ]
then
    echo "Provide path to draft markdown file as input e.g.,"
    echo ""
    echo "$0 /drafts/my_draft.md"
    echo ""
    exit 1
fi

function render() {
    kramdown-rfc "$1" > "${1/.md/.xml}"
    xml2rfc --html "${1/.md/.xml}"
}

function serve() {
    python3 -m http.server -d "$1" 4343 &
}

echo "Watching $WATCH_FILE"
echo "HTTP dir is $HTTP_DIR"

render "$WATCH_FILE"
serve "$HTTP_DIR"
echo "Open your browser to: http://127.0.0.1:4343/$(basename "${WATCH_FILE/.md/.html}")"

inotifywait -qm --event modify --format '%w' "$WATCH_FILE" | while read -r _
do
    render "$WATCH_FILE" || true
    sleep 1
done
