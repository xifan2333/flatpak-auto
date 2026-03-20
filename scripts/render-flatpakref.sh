#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "Usage: $0 <product-name> [output-path]" >&2
  exit 1
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
META_FILE="${ROOT_DIR}/metadata/repository.env"
product_name="$1"
product_file="${ROOT_DIR}/products/${product_name}/product.env"

if [[ ! -f "${META_FILE}" ]]; then
  echo "Metadata file missing: ${META_FILE}" >&2
  exit 1
fi

if [[ ! -f "${product_file}" ]]; then
  echo "Product file missing: ${product_file}" >&2
  exit 1
fi

# shellcheck disable=SC1090
source "${META_FILE}"
# shellcheck disable=SC1090
source "${product_file}"

: "${APP_ID:?Missing APP_ID}"
: "${BRANCH:?Missing BRANCH}"
: "${TITLE:?Missing TITLE}"
: "${HOMEPAGE:?Missing HOMEPAGE}"
: "${REMOTE_URL:?Missing REMOTE_URL}"
: "${RUNTIME_REPO:?Missing RUNTIME_REPO}"

gpg_key="${GPG_KEY_BASE64:-BASE64_ENCODED_PUBLIC_KEY}"
output_path="${2:-${ROOT_DIR}/refs/${APP_ID}.flatpakref.example}"

cat > "${output_path}" <<EOF
[Flatpak Ref]
Version=1
Name=${APP_ID}
Branch=${BRANCH}
Title=${TITLE}
IsRuntime=false
Url=${REMOTE_URL}
RuntimeRepo=${RUNTIME_REPO}
Homepage=${HOMEPAGE}
GPGKey=${gpg_key}
EOF

echo "Wrote ${output_path}"
