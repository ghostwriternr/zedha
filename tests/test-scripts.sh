#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

test_root=$(mktemp -d)
trap 'rm -rf "$test_root"' EXIT

assert_file_contains() {
  local file=$1
  local expected=$2
  if ! grep -Fq "$expected" "$file"; then
    echo "expected $file to contain: $expected" >&2
    echo "actual contents:" >&2
    cat "$file" >&2
    exit 1
  fi
}

create_upstream_repo() {
  local upstream=$1
  mkdir -p "$upstream"
  git -C "$upstream" init --quiet
  git -C "$upstream" config user.name "Zedha Test"
  git -C "$upstream" config user.email "zedha-test@example.com"
  printf 'base\n' > "$upstream/fixture.txt"
  git -C "$upstream" add fixture.txt
  git -C "$upstream" commit --quiet -m "Create fixture"
  git -C "$upstream" tag v1.2.3
}

test_fetch_upstream_checks_out_pinned_commit() {
  local upstream="$test_root/upstream"
  local checkout="$test_root/checkout"
  create_upstream_repo "$upstream"
  local commit
  commit=$(git -C "$upstream" rev-parse HEAD)

  local pin_file="$test_root/stable.json"
  cat > "$pin_file" <<JSON
{
  "tag": "v1.2.3",
  "commit": "$commit"
}
JSON

  ZEDHA_UPSTREAM_REPO="$upstream" ZEDHA_UPSTREAM_PIN="$pin_file" "$repo_root/scripts/fetch-upstream" "$checkout"

  local actual
  actual=$(git -C "$checkout" rev-parse HEAD)
  if [[ "$actual" != "$commit" ]]; then
    echo "expected checkout at $commit, got $actual" >&2
    exit 1
  fi

  if [[ "$(git -C "$checkout" rev-parse --is-shallow-repository)" != "true" ]]; then
    echo "expected fetch-upstream to create a shallow checkout" >&2
    exit 1
  fi
}

test_apply_patches_applies_patch_files_in_order() {
  local upstream="$test_root/upstream-for-patches"
  local checkout="$test_root/checkout-for-patches"
  create_upstream_repo "$upstream"
  git clone --quiet "$upstream" "$checkout"

  local patch_dir="$test_root/patches"
  mkdir -p "$patch_dir"
  cat > "$patch_dir/0001-change-fixture.patch" <<'PATCH'
diff --git a/fixture.txt b/fixture.txt
index df967b9..3e75765 100644
--- a/fixture.txt
+++ b/fixture.txt
@@ -1 +1,2 @@
 base
+first
PATCH
  cat > "$patch_dir/0002-change-fixture.patch" <<'PATCH'
diff --git a/fixture.txt b/fixture.txt
index 3e75765..f6bd61a 100644
--- a/fixture.txt
+++ b/fixture.txt
@@ -1,2 +1,3 @@
 base
 first
+second
PATCH

  ZEDHA_PATCH_DIR="$patch_dir" "$repo_root/scripts/apply-patches" "$checkout"

  assert_file_contains "$checkout/fixture.txt" "first"
  assert_file_contains "$checkout/fixture.txt" "second"
}

test_test_script_runs_configured_command_in_source_dir() {
  local source="$test_root/source-for-test"
  mkdir -p "$source"
  printf 'ok\n' > "$source/fixture.txt"

  ZEDHA_TEST_COMMAND='test -f fixture.txt' "$repo_root/scripts/test" "$source"
}

test_fetch_upstream_checks_out_pinned_commit
test_apply_patches_applies_patch_files_in_order
test_test_script_runs_configured_command_in_source_dir

echo "All script tests passed"
