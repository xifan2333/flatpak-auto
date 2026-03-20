# fcitx5-vinput

This repository stays reusable. `fcitx5-vinput` is simply the first product
published from it.

## Product Identity

- App ID: `org.fcitx.Fcitx5.Addon.Vinput`
- Branch: `stable`
- Upstream repository: `xifan2333/fcitx5-vinput`
- Release artifact: `fcitx5-vinput.flatpak`

## Current Publishing Goal

Publish one installable Flatpak artifact for:

- `org.fcitx.Fcitx5.Addon.Vinput/stable`

The shared repository model remains unchanged:

- one reusable remote
- multiple products can be added later
- each product gets its own `.flatpakref`

## First Release Inputs

The upstream release pipeline currently publishes a Flatpak bundle asset:

- file: `fcitx5-vinput.flatpak`
- source: GitHub Releases from `xifan2333/fcitx5-vinput`

The current upstream manifest characteristics are:

- runtime: `org.fcitx.Fcitx5`
- branch: `stable`
- build-extension: `true`

This repository should consume the released bundle artifact, not rebuild the
application from source.

## Required Public Endpoints

Current GitHub Pages target:

- OSTree repo: `https://xifan2333.github.io/flatpak-auto/repo/`
- Remote file: `https://xifan2333.github.io/flatpak-auto/xifan.flatpakrepo`
- Ref file:
  `https://xifan2333.github.io/flatpak-auto/refs/org.fcitx.Fcitx5.Addon.Vinput.flatpakref`

## Next Steps For This Product

1. Generate or import the Flatpak signing key.
2. Fill the public key into the remote and ref templates.
3. Download `fcitx5-vinput.flatpak` from GitHub Releases.
4. Import the bundle into `repo/` with `flatpak build-import-bundle`.
5. Publish the signed repository over HTTPS.
