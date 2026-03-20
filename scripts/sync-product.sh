#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
Usage: sync-product.sh <product-name> [--force] [--version <version>] [--repo-dir <repo-dir>]
EOF
  exit 1
}

if [[ $# -lt 1 ]]; then
  usage
fi

product_name="$1"
shift

force=0
version=""
repo_dir="repo"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --force)
      force=1
      shift
      ;;
    --version)
      [[ $# -ge 2 ]] || usage
      version="$2"
      shift 2
      ;;
    --repo-dir)
      [[ $# -ge 2 ]] || usage
      repo_dir="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      ;;
  esac
done

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
product_dir="${ROOT_DIR}/products/${product_name}"
product_file="${product_dir}/product.env"
state_file="${product_dir}/state.env"
upstream_file="${product_dir}/upstream.sh"

[[ -f "${product_file}" ]] || { echo "Product file missing: ${product_file}" >&2; exit 1; }
[[ -f "${upstream_file}" ]] || { echo "Upstream file missing: ${upstream_file}" >&2; exit 1; }

# shellcheck disable=SC1090
source "${product_file}"
# shellcheck disable=SC1090
source "${upstream_file}"
if [[ -f "${state_file}" ]]; then
  # shellcheck disable=SC1090
  source "${state_file}"
fi

: "${RELEASE_ASSET:?Missing RELEASE_ASSET}"

current_version="${CURRENT_VERSION:-}"
current_bundle_url="${CURRENT_BUNDLE_URL:-}"

if [[ "${repo_dir}" = /* ]]; then
  repo_path="${repo_dir}"
else
  repo_path="${ROOT_DIR}/${repo_dir}"
fi

repo_ready=0
if [[ -f "${repo_path}/config" && -d "${repo_path}/objects" ]]; then
  repo_ready=1
fi

if [[ -z "${version}" ]]; then
  version="$(product_detect_latest)"
fi

bundle_url="$(product_get_bundle_url "${version}")"

if [[ ${force} -eq 0 && ${repo_ready} -eq 1 && -n "${current_version}" && "${current_version}" == "${version}" && -n "${current_bundle_url}" && "${current_bundle_url}" == "${bundle_url}" ]]; then
  echo "Product ${product_name} already at ${version}; skipping import"
  exit 0
fi

tmpdir="$(mktemp -d)"
trap 'rm -rf "${tmpdir}"' EXIT

bundle_path="${tmpdir}/${RELEASE_ASSET}"
curl -fsSL --retry 3 --retry-delay 2 -o "${bundle_path}" "${bundle_url}"

bash "${ROOT_DIR}/scripts/import-release-bundle.sh" "${bundle_path}" "${repo_dir}"

cat > "${state_file}" <<EOF
CURRENT_VERSION=${version}
CURRENT_BUNDLE_URL=${bundle_url}
EOF

echo "Synced ${product_name} -> ${version}"
