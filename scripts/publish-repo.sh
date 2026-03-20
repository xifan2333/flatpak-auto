#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
META_FILE="${ROOT_DIR}/metadata/repository.env"
REPO_DIR="${ROOT_DIR}/repo"
SITE_DIR="${ROOT_DIR}/public"

[[ -f "${META_FILE}" ]] || { echo "Metadata file missing: ${META_FILE}" >&2; exit 1; }

# shellcheck disable=SC1090
source "${META_FILE}"

: "${REMOTE_NAME:?Missing REMOTE_NAME}"

mkdir -p "${REPO_DIR}" "${ROOT_DIR}/refs" "${SITE_DIR}"
find "${ROOT_DIR}/refs" -maxdepth 1 -type f -name '*.flatpakref' -delete

gpg_homedir=""
gpg_key_id="${FLATPAK_GPG_KEY_ID:-}"
public_key_b64="${FLATPAK_GPG_PUBLIC_KEY_BASE64:-}"

cleanup() {
  if [[ -n "${gpg_homedir}" && -d "${gpg_homedir}" ]]; then
    rm -rf "${gpg_homedir}"
  fi
}
trap cleanup EXIT

if [[ -z "${FLATPAK_GPG_PRIVATE_KEY_BASE64:-}" ]]; then
  echo "Missing GPG private key. Set FLATPAK_GPG_PRIVATE_KEY_BASE64 before publishing." >&2
  exit 1
fi

gpg_homedir="$(mktemp -d)"
chmod 700 "${gpg_homedir}"
printf '%s' "${FLATPAK_GPG_PRIVATE_KEY_BASE64}" | base64 -d | gpg --batch --homedir "${gpg_homedir}" --import
if [[ -z "${gpg_key_id}" ]]; then
  gpg_key_id="$(gpg --batch --homedir "${gpg_homedir}" --list-secret-keys --with-colons | awk -F: '$1 == "sec" { print $5; exit }')"
fi
if [[ -z "${public_key_b64}" ]]; then
  public_key_b64="$(gpg --batch --homedir "${gpg_homedir}" --export "${gpg_key_id}" | base64 | tr -d '\n')"
fi

if [[ -z "${public_key_b64}" ]]; then
  echo "Missing GPG public key. Set FLATPAK_GPG_PUBLIC_KEY_BASE64 or FLATPAK_GPG_PRIVATE_KEY_BASE64." >&2
  exit 1
fi

GPG_KEY_BASE64="${public_key_b64}" bash "${ROOT_DIR}/scripts/render-flatpakrepo.sh" "${ROOT_DIR}/${REMOTE_NAME}.flatpakrepo"

while IFS= read -r -d '' product_file; do
  product_dir="$(dirname "${product_file}")"
  product_name="$(basename "${product_dir}")"
  product_env="${product_dir}/product.env"
  # shellcheck disable=SC1090
  source "${product_env}"
  output_path="${ROOT_DIR}/refs/${APP_ID}.flatpakref"
  GPG_KEY_BASE64="${public_key_b64}" bash "${ROOT_DIR}/scripts/render-flatpakref.sh" "${product_name}" "${output_path}"
done < <(find "${ROOT_DIR}/products" -mindepth 2 -maxdepth 2 -name product.env -print0 | sort -z)

update_args=(flatpak build-update-repo "${REPO_DIR}" --generate-static-deltas)
if [[ -n "${gpg_key_id}" && -n "${gpg_homedir}" ]]; then
  update_args+=(--gpg-sign="${gpg_key_id}" --gpg-homedir="${gpg_homedir}")
fi
"${update_args[@]}"

rm -rf "${SITE_DIR}"
mkdir -p "${SITE_DIR}/refs"
cp -a "${REPO_DIR}" "${SITE_DIR}/repo"
while IFS= read -r -d '' ref_file; do
  cp "${ref_file}" "${SITE_DIR}/refs/"
done < <(find "${ROOT_DIR}/refs" -maxdepth 1 -type f -name '*.flatpakref' -print0 | sort -z)
cp "${ROOT_DIR}/${REMOTE_NAME}.flatpakrepo" "${SITE_DIR}/"

echo "Published site tree to ${SITE_DIR}"
