#!/bin/bash

# TODO: move common parts here

case "$(uname -s)" in
	Linux)  OS=linux;;
	Darwin) OS=darwin;;
	*_NT-*) OS=windows;;
esac

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/external/lldb-utils/build-${OS}.sh" "$@"
