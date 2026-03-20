#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "Usage: $0 <bundle-path> [repo-dir]" >&2
  exit 1
fi

bundle_path="$1"
repo_dir="${2:-${ROOT_DIR}/repo}"

if [[ ! -f "${bundle_path}" ]]; then
  echo "Bundle not found: ${bundle_path}" >&2
  exit 1
fi

mkdir -p "${repo_dir}"

if [[ ! -f "${repo_dir}/config" ]]; then
  ostree init --repo="${repo_dir}" --mode=archive-z2
fi

flatpak build-import-bundle --no-update-summary "${repo_dir}" "${bundle_path}"

echo "Imported bundle into ${repo_dir}"
