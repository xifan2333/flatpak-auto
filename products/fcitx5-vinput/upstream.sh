#!/usr/bin/env bash
set -euo pipefail

github_api_get() {
  local url="$1"
  local -a args
  args=(
    -fsSL
    -H 'Accept: application/vnd.github+json'
    -H 'X-GitHub-Api-Version: 2022-11-28'
    -H 'User-Agent: flatpak-auto'
  )

  if [[ -n "${GH_TOKEN:-}" ]]; then
    args+=(-H "Authorization: Bearer ${GH_TOKEN}")
  elif [[ -n "${GITHUB_TOKEN:-}" ]]; then
    args+=(-H "Authorization: Bearer ${GITHUB_TOKEN}")
  fi

  curl "${args[@]}" "${url}"
}

product_detect_latest() {
  local api_url="https://api.github.com/repos/xifan2333/fcitx5-vinput/releases/latest"
  local json_data version

  json_data="$(github_api_get "${api_url}")"
  if [[ -z "${json_data}" ]]; then
    echo "Failed to fetch data from ${api_url}" >&2
    return 1
  fi

  version="$(echo "${json_data}" | jq -r '.tag_name // empty')"
  if [[ -z "${version}" ]]; then
    echo "Failed to parse tag_name from API response" >&2
    return 1
  fi

  version="${version#v}"
  printf '%s\n' "${version}"
}

product_get_bundle_url() {
  local version="$1"
  local json_data api_url bundle_url

  api_url="https://api.github.com/repos/xifan2333/fcitx5-vinput/releases/tags/v${version}"
  json_data="$(github_api_get "${api_url}")"
  if [[ -z "${json_data}" ]]; then
    echo "Failed to fetch data from ${api_url}" >&2
    return 1
  fi

  bundle_url="$(echo "${json_data}" | jq -r --arg name "${RELEASE_ASSET}" '.assets[] | select(.name == $name) | .browser_download_url' | head -n1)"
  if [[ -z "${bundle_url}" || "${bundle_url}" == "null" ]]; then
    echo "Failed to find release asset ${RELEASE_ASSET} for version ${version}" >&2
    return 1
  fi

  printf '%s\n' "${bundle_url}"
}
