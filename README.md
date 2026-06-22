# Zedha

Zedha is a personal-first, public-compatible downstream distribution of [Zed](https://github.com/zed-industries/zed).

It follows a VSCodium-style model: this repository does not vendor Zed source. Instead it pins an upstream Zed stable release, fetches that source, applies a small ordered patch set, and validates the resulting tree.

## Current milestone

Milestone 1 proves the distribution model:

- fetch upstream Zed at the pinned stable release
- apply Zedha patches in lexical order
- verify the patched stable-channel tree is branded as Zedha
- run targeted terminal launcher tests

Native updates, signed DMGs, notarization, and release publishing are intentionally deferred.

## Product identity target

```text
App name:       Zedha
CLI command:    zedha
Bundle ID:      me.ghostwriternr.Zedha
Update channel: zedha
```

Official Zed remains separate from Zedha.

## Repository layout

```text
upstream/stable.json       pinned upstream Zed stable release
patches/*.patch            ordered downstream patches
scripts/fetch-upstream     clone pinned upstream source
scripts/apply-patches      apply patches to a Zed checkout
scripts/check-identity     verify patched Zedha product identity
scripts/test               run targeted validation
scripts/build-macos-artifact build a macOS DMG and copy it to artifacts/
tests/test-scripts.sh      script behavior tests
```

## Local validation

Run the script tests:

```bash
./tests/test-scripts.sh
```

Fetch upstream Zed into `.work/zed`:

```bash
./scripts/fetch-upstream
```

Apply Zedha patches:

```bash
./scripts/apply-patches
```

Verify Zedha identity:

```bash
./scripts/check-identity
```

Run targeted validation:

```bash
./scripts/test
```

Build a macOS DMG artifact:

```bash
./scripts/build-macos-artifact .work/zed aarch64-apple-darwin
```

The wrapper copies Zed's generated `Zed-aarch64.dmg` to `artifacts/Zedha-aarch64.dmg` for distribution workflow artifacts.

For local development, you can point `fetch-upstream` at an existing Zed checkout:

```bash
ZEDHA_UPSTREAM_REPO=~/github/zed ./scripts/fetch-upstream
```

## Patch refresh workflow

The normal Zed checkout remains the ergonomic place to develop changes. Once a downstream change is ready, export it as a patch and copy it into `patches/`.

Example:

```bash
git -C ~/github/zed format-patch --no-stat --no-signature \
  --output-directory ~/github/zedha/patches v1.7.2..patched-main
```

Keep behavior patches separate from product identity and update-feed patches so upstream conflicts are easier to review.
