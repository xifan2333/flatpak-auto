#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
META_FILE="${ROOT_DIR}/metadata/repository.env"

if [[ ! -f "${META_FILE}" ]]; then
  echo "Metadata file missing: ${META_FILE}" >&2
  exit 1
fi

# shellcheck disable=SC1090
source "${META_FILE}"

: "${REMOTE_NAME:?Missing REMOTE_NAME}"
: "${REMOTE_TITLE:?Missing REMOTE_TITLE}"
: "${REMOTE_COMMENT:?Missing REMOTE_COMMENT}"
: "${REMOTE_HOMEPAGE:?Missing REMOTE_HOMEPAGE}"
: "${REMOTE_URL:?Missing REMOTE_URL}"
: "${DEFAULT_BRANCH:?Missing DEFAULT_BRANCH}"

gpg_key="${GPG_KEY_BASE64:-BASE64_ENCODED_PUBLIC_KEY}"
output_path="${1:-${ROOT_DIR}/${REMOTE_NAME}.flatpakrepo.example}"

cat > "${output_path}" <<EOF
[Flatpak Repo]
Version=1
Title=${REMOTE_TITLE}
Comment=${REMOTE_COMMENT}
Homepage=${REMOTE_HOMEPAGE}
Url=${REMOTE_URL}
DefaultBranch=${DEFAULT_BRANCH}
GPGKey=${gpg_key}
EOF

echo "Wrote ${output_path}"
