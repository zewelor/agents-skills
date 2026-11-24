#!/usr/bin/env bash
set -euo pipefail

if (( $# != 1 )); then
    echo "Usage: $0 /absolute/path/to/context" >&2
    exit 1
fi

if [[ $1 != /* || ! -d $1 ]]; then
    echo "Expected an absolute path to an existing context directory." >&2
    exit 1
fi

printf 'FROM scratch\nCOPY . /\n' |
    docker build -f - --output type=tar,dest=- "$1" |
    python3 -I -c '
import json
import sys
import tarfile

with tarfile.open(fileobj=sys.stdin.buffer, mode="r|") as archive:
    paths = sorted(entry.name for entry in archive
                   if entry.isfile() or entry.issym() or entry.islnk())
for path in paths:
    print(json.dumps("./" + path)[1:-1])
'
