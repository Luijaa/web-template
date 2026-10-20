#!/usr/bin/env bash
# Run trivy in Docker with the repo copied in as /src — `docker cp`, never a bind mount.
# A bind mount of the checkout breaks when Docker runs on another filesystem (self-hosted CI runner in a
# container that talks to the host's Docker): the path does not exist there, so the container sees an
# EMPTY /src with no error and trivy "passes". Used by CI and by `make license` (docs/testing.md "CI runners").
#
# usage: scripts/trivy.sh <trivy args…>
#   scripts/trivy.sh fs --exit-code 1 --ignorefile /src/.trivyignore /src
#   scripts/trivy.sh image --ignorefile /src/.trivyignore my-image:local      (local images: docker.sock is mounted)
#   GO_MODULES=1 scripts/trivy.sh fs --scanners license … /src                 (Go: copies the modules the build uses)
# Copies tracked + untracked files that are not gitignored (no .git, node_modules, .env).
# Passes TRIVY_USERNAME / TRIVY_PASSWORD through when set (private registries). Output goes to stdout.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

image="${TRIVY_IMAGE:-aquasec/trivy:0.74.0}"
args=(-v /var/run/docker.sock:/var/run/docker.sock)
for v in TRIVY_USERNAME TRIVY_PASSWORD; do
  if [ -n "${!v:-}" ]; then args+=(-e "$v"); fi
done
if [ "${GO_MODULES:-}" = 1 ]; then args+=(-e GOPATH=/tmp/gopath); fi

cid="$(docker create "${args[@]}" "$image" "$@")"
tmp="$(mktemp -d)"
trap 'docker rm -f "$cid" > /dev/null; rm -rf "$tmp"' EXIT

# /src: files git would see (skips deleted-but-tracked paths so tar does not fail)
mkdir "$tmp/src" && docker cp -q "$tmp/src" "$cid:/src"
git ls-files -z --cached --others --exclude-standard \
  | python3 -c 'import os, sys; sys.stdout.buffer.write(b"\0".join(p for p in sys.stdin.buffer.read().split(b"\0") if p and os.path.lexists(p)))' \
  | tar --null -T - -cf - | docker cp -q - "$cid:/src"

if [ "${GO_MODULES:-}" = 1 ]; then
  modcache="$(go env GOMODCACHE)"
  case "$modcache" in */pkg/mod) ;; *) echo "trivy.sh: GOMODCACHE must end in /pkg/mod (got $modcache)" >&2; exit 1 ;; esac
  gopath="${modcache%/pkg/mod}"
  go list -m -f '{{if and (not .Main) .Dir}}{{.Dir}}{{end}}' all \
    | awk -v p="$gopath/" 'index($0, p "pkg/mod/") == 1 { print substr($0, length(p) + 1) }' | sort -u > "$tmp/modules"
  mkdir "$tmp/gopath" && docker cp -q "$tmp/gopath" "$cid:/tmp/gopath"
  if [ -s "$tmp/modules" ]; then tar -C "$gopath" -cf - -T "$tmp/modules" | docker cp -q - "$cid:/tmp/gopath"; fi
fi

docker start -a "$cid"   # exit code = trivy's
