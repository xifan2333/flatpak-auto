#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
META_FILE="${ROOT_DIR}/metadata/repository.env"
OUTPUT_PATH="${1:-${ROOT_DIR}/public/index.html}"

[[ -f "${META_FILE}" ]] || { echo "Metadata file missing: ${META_FILE}" >&2; exit 1; }

# shellcheck disable=SC1090
source "${META_FILE}"

: "${REMOTE_NAME:?Missing REMOTE_NAME}"
: "${REMOTE_TITLE:?Missing REMOTE_TITLE}"
: "${REMOTE_COMMENT:?Missing REMOTE_COMMENT}"
: "${REMOTE_HOMEPAGE:?Missing REMOTE_HOMEPAGE}"
: "${REMOTE_URL:?Missing REMOTE_URL}"
: "${REMOTE_FILE_URL:?Missing REMOTE_FILE_URL}"

html_escape() {
  local text="${1:-}"
  text="${text//&/&amp;}"
  text="${text//</&lt;}"
  text="${text//>/&gt;}"
  printf '%s' "${text}"
}

command_escape() {
  html_escape "$1"
}

products_html=""

while IFS= read -r -d '' product_file; do
  product_dir="$(dirname "${product_file}")"
  product_name="$(basename "${product_dir}")"
  state_file="${product_dir}/state.env"

  unset PRODUCT_NAME APP_ID BRANCH TITLE DESCRIPTION HOMEPAGE UPSTREAM_REPO RELEASE_ASSET CURRENT_VERSION CURRENT_BUNDLE_URL
  # shellcheck disable=SC1090
  source "${product_file}"
  if [[ -f "${state_file}" ]]; then
    # shellcheck disable=SC1090
    source "${state_file}"
  fi

  version="${CURRENT_VERSION:-pending}"
  ref_url="${REMOTE_FILE_URL%/*}/refs/${APP_ID}.flatpakref"
  install_cmd="flatpak install ${REMOTE_NAME} ${APP_ID}"
  direct_cmd="flatpak install ${ref_url}"

  products_html+=$(cat <<EOF
        <article class="product-card">
          <div class="product-head">
            <div>
              <p class="eyebrow">Package</p>
              <h2>$(html_escape "${TITLE}")</h2>
            </div>
            <span class="version-badge">$(html_escape "${version}")</span>
          </div>
          <p class="product-desc">$(html_escape "${DESCRIPTION:-No description available.}")</p>
          <dl class="meta-grid">
            <div>
              <dt>App ID</dt>
              <dd><code>$(html_escape "${APP_ID}")</code></dd>
            </div>
            <div>
              <dt>Branch</dt>
              <dd><code>$(html_escape "${BRANCH}")</code></dd>
            </div>
            <div>
              <dt>Upstream</dt>
              <dd><a href="https://github.com/$(html_escape "${UPSTREAM_REPO}")">$(html_escape "${UPSTREAM_REPO}")</a></dd>
            </div>
            <div>
              <dt>Flatpakref</dt>
              <dd><a href="$(html_escape "${ref_url}")">download</a></dd>
            </div>
          </dl>
          <div class="command-block">
            <p class="command-label">Install after adding the remote</p>
            <pre><code>$(command_escape "${install_cmd}")</code></pre>
          </div>
          <div class="command-block alternate">
            <p class="command-label">Direct install</p>
            <pre><code>$(command_escape "${direct_cmd}")</code></pre>
          </div>
        </article>
EOF
)
done < <(find "${ROOT_DIR}/products" -mindepth 2 -maxdepth 2 -name product.env -print0 | sort -z)

mkdir -p "$(dirname "${OUTPUT_PATH}")"

cat > "${OUTPUT_PATH}" <<EOF
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>$(html_escape "${REMOTE_TITLE}")</title>
    <meta name="description" content="$(html_escape "${REMOTE_COMMENT}")">
    <style>
      :root {
        --bg: #f6f1e8;
        --paper: rgba(255, 251, 245, 0.9);
        --ink: #1e1c1a;
        --muted: #6d655d;
        --line: rgba(44, 34, 24, 0.14);
        --accent: #bb4d00;
        --accent-soft: #ffcf99;
        --shadow: 0 18px 50px rgba(55, 38, 14, 0.12);
      }

      * { box-sizing: border-box; }

      body {
        margin: 0;
        color: var(--ink);
        background:
          radial-gradient(circle at top left, rgba(255, 214, 153, 0.6), transparent 34%),
          radial-gradient(circle at top right, rgba(231, 90, 0, 0.14), transparent 26%),
          linear-gradient(180deg, #f7efe4 0%, #f3ecdf 48%, #efe8dc 100%);
        font-family: "Avenir Next", "Helvetica Neue", "Noto Sans", sans-serif;
      }

      a {
        color: inherit;
      }

      .page {
        width: min(1120px, calc(100vw - 32px));
        margin: 0 auto;
        padding: 36px 0 56px;
      }

      .hero {
        position: relative;
        overflow: hidden;
        padding: 34px;
        border: 1px solid var(--line);
        border-radius: 28px;
        background:
          linear-gradient(135deg, rgba(255, 255, 255, 0.85), rgba(255, 245, 231, 0.88)),
          linear-gradient(120deg, rgba(255, 182, 93, 0.16), rgba(187, 77, 0, 0.08));
        box-shadow: var(--shadow);
      }

      .hero::after {
        content: "";
        position: absolute;
        inset: auto -80px -80px auto;
        width: 220px;
        height: 220px;
        border-radius: 999px;
        background: radial-gradient(circle, rgba(187, 77, 0, 0.18), transparent 70%);
      }

      .eyebrow {
        margin: 0 0 10px;
        color: var(--accent);
        font-size: 12px;
        font-weight: 700;
        letter-spacing: 0.16em;
        text-transform: uppercase;
      }

      h1, h2, h3, code, pre {
        font-family: "Iosevka Aile", "IBM Plex Sans", "SFMono-Regular", monospace;
      }

      h1 {
        margin: 0;
        font-size: clamp(2.3rem, 5vw, 4.5rem);
        line-height: 0.96;
        max-width: 10ch;
      }

      .hero-copy {
        max-width: 760px;
        margin-top: 18px;
        font-size: 1.02rem;
        line-height: 1.7;
        color: var(--muted);
      }

      .quick-grid {
        display: grid;
        grid-template-columns: repeat(2, minmax(0, 1fr));
        gap: 18px;
        margin-top: 24px;
      }

      .panel {
        padding: 20px;
        border: 1px solid var(--line);
        border-radius: 20px;
        background: var(--paper);
      }

      .panel h3 {
        margin: 0 0 12px;
        font-size: 1rem;
      }

      .panel p {
        margin: 0 0 12px;
        color: var(--muted);
        line-height: 1.6;
      }

      pre {
        margin: 0;
        padding: 14px 16px;
        overflow-x: auto;
        border-radius: 16px;
        background: #201812;
        color: #fff6eb;
        font-size: 0.94rem;
        line-height: 1.5;
      }

      .subhead {
        display: flex;
        align-items: center;
        justify-content: space-between;
        gap: 12px;
        margin: 34px 0 16px;
      }

      .subhead h2 {
        margin: 0;
        font-size: clamp(1.4rem, 2vw, 2rem);
      }

      .subhead p {
        margin: 0;
        color: var(--muted);
      }

      .pill-link {
        display: inline-flex;
        align-items: center;
        gap: 10px;
        padding: 10px 14px;
        border-radius: 999px;
        border: 1px solid rgba(187, 77, 0, 0.2);
        background: rgba(255, 241, 224, 0.9);
        text-decoration: none;
        font-size: 0.92rem;
      }

      .products {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
        gap: 18px;
      }

      .product-card {
        padding: 22px;
        border: 1px solid var(--line);
        border-radius: 22px;
        background: var(--paper);
        box-shadow: var(--shadow);
      }

      .product-head {
        display: flex;
        align-items: flex-start;
        justify-content: space-between;
        gap: 12px;
      }

      .product-head h2 {
        margin: 0;
        font-size: 1.32rem;
      }

      .version-badge {
        flex: none;
        padding: 8px 10px;
        border-radius: 999px;
        background: var(--accent-soft);
        font-size: 0.84rem;
        font-weight: 700;
      }

      .product-desc {
        min-height: 3.2em;
        color: var(--muted);
        line-height: 1.6;
      }

      .meta-grid {
        display: grid;
        grid-template-columns: repeat(2, minmax(0, 1fr));
        gap: 12px;
        margin: 18px 0;
      }

      .meta-grid div {
        padding: 12px;
        border-radius: 16px;
        background: rgba(255, 250, 243, 0.9);
        border: 1px solid var(--line);
      }

      .meta-grid dt {
        margin-bottom: 6px;
        color: var(--muted);
        font-size: 0.8rem;
        text-transform: uppercase;
        letter-spacing: 0.08em;
      }

      .meta-grid dd {
        margin: 0;
        overflow-wrap: anywhere;
      }

      .command-block {
        margin-top: 14px;
      }

      .command-block.alternate pre {
        background: #2c2218;
      }

      .command-label {
        margin: 0 0 8px;
        color: var(--muted);
        font-size: 0.88rem;
      }

      footer {
        margin-top: 30px;
        padding: 18px 0 4px;
        color: var(--muted);
        font-size: 0.92rem;
      }

      @media (max-width: 760px) {
        .page {
          width: min(100vw - 20px, 1120px);
          padding-top: 18px;
        }

        .hero {
          padding: 22px;
          border-radius: 24px;
        }

        .quick-grid,
        .meta-grid {
          grid-template-columns: 1fr;
        }

        .subhead {
          flex-direction: column;
          align-items: flex-start;
        }
      }
    </style>
  </head>
  <body>
    <main class="page">
      <section class="hero">
        <p class="eyebrow">Reusable Flatpak Remote</p>
        <h1>Install personal packages from one remote.</h1>
        <p class="hero-copy">
          $(html_escape "${REMOTE_COMMENT}") This page is generated from product metadata and
          updated automatically by GitHub Actions whenever a tracked upstream
          release changes.
        </p>
        <div class="quick-grid">
          <section class="panel">
            <h3>Add the remote</h3>
            <p>Run this once on a machine. After that, every package below can be installed by app ID.</p>
            <pre><code>flatpak remote-add --if-not-exists $(command_escape "${REMOTE_NAME}") $(command_escape "${REMOTE_FILE_URL}")</code></pre>
          </section>
          <section class="panel">
            <h3>Repository files</h3>
            <p>Use the remote file for normal setup, or browse individual package refs directly.</p>
            <p><a class="pill-link" href="$(html_escape "${REMOTE_FILE_URL}")">Open .flatpakrepo</a></p>
            <p><a class="pill-link" href="$(html_escape "${REMOTE_URL}")">Browse OSTree repo</a></p>
          </section>
        </div>
      </section>

      <section>
        <div class="subhead">
          <div>
            <h2>Package List</h2>
            <p>Each package card includes the install command and a direct flatpakref link.</p>
          </div>
          <a class="pill-link" href="$(html_escape "${REMOTE_HOMEPAGE}")">Repository owner</a>
        </div>
        <div class="products">
${products_html}
        </div>
      </section>

      <footer>
        Remote name: <code>$(html_escape "${REMOTE_NAME}")</code> · Default branch:
        <code>$(html_escape "${DEFAULT_BRANCH}")</code>
      </footer>
    </main>
  </body>
</html>
EOF

echo "Wrote ${OUTPUT_PATH}"
