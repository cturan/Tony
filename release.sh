#!/usr/bin/env bash
# Builds every release binary of Tony into release/ with netv3.tnns embedded and profile-guided (pgo.uci).
# usage: ./release.sh            (JOBS=4 parallel builds by default)
#        JOBS=8 ./release.sh
set -u
cd "$(dirname "$0")"

VERSION=0.5
NET=netv3.tnns
JOBS=${JOBS:-4}

mkdir -p release
rm -f release/tony-*

build() {
  local arch="$1" cpu="$2" isa="$3" name="$4"
  if lua t.lua tony.t --arch "$arch" --cpu "$cpu" --instruction "$isa" --gom "$NET" --pgo pgo.uci --output "release/$name" > "release/.$name.log" 2>&1; then
    echo "OK   $name"
    rm -f "release/.$name.log"
  else
    echo "FAIL $name" >&2
    cat "release/.$name.log" >&2
    return 1
  fi
}

targets=(
  "macos arm64 neon"
  "macos x86_64 sse2" "macos x86_64 avx" "macos x86_64 avx2" "macos x86_64 avx512" "macos x86_64 avx512bw"
  "linux arm64 neon"
  "linux x86_64 sse2" "linux x86_64 avx" "linux x86_64 avx2" "linux x86_64 avx512" "linux x86_64 avx512bw"
  "windows x86_64 sse2" "windows x86_64 avx" "windows x86_64 avx2" "windows x86_64 avx512" "windows x86_64 avx512bw"
)

fail=0
pids=()
for t in "${targets[@]}"; do
  set -- $t
  name="tony-$VERSION-$1-$2-$3"
  [ "$1" = windows ] && name="$name.exe"
  build "$1" "$2" "$3" "$name" &
  pids+=($!)
  if [ "${#pids[@]}" -ge "$JOBS" ]; then
    wait "${pids[0]}" || fail=1
    pids=("${pids[@]:1}")
  fi
done
for pid in "${pids[@]}"; do
  wait "$pid" || fail=1
done

echo '---'
ls -lh release | awk 'NR > 1 {print $5, $9}'
exit $fail
