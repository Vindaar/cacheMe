#!/bin/sh
set -eu

cd "$(dirname "$0")/.."
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
nim c -d:H5_FUTURE --out:"$work/check" tests/tests.nim
cd "$work"
./check populate
./check reuse
