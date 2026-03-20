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
            <h2>$(html_escape "${TITLE}")</h2>
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
          <div class="command-row">
            <span class="command-label">Install</span>
            <pre><code>$(command_escape "${install_cmd}")</code></pre>
          </div>
          <div class="command-row">
            <span class="command-label">Direct</span>
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
        --bg: #f7f7f5;
        --panel: #ffffff;
        --ink: #171717;
        --muted: #666;
        --line: #e7e5e1;
        --accent: #b45309;
        --accent-soft: #fff1e6;
      }

      * { box-sizing: border-box; }

      body {
        margin: 0;
        color: var(--ink);
        background: var(--bg);
        font-family: "Avenir Next", "Helvetica Neue", "Noto Sans", sans-serif;
      }

      a {
        color: var(--accent);
        text-decoration: none;
      }

      a:hover {
        text-decoration: underline;
      }

      .page {
        width: min(980px, calc(100vw - 28px));
        margin: 0 auto;
        padding: 22px 0 40px;
      }

      .hero {
        padding: 22px 24px;
        border: 1px solid var(--line);
        border-radius: 18px;
        background: var(--panel);
      }

      .eyebrow {
        margin: 0 0 8px;
        color: var(--accent);
        font-size: 11px;
        font-weight: 700;
        letter-spacing: 0.14em;
        text-transform: uppercase;
      }

      h1, h2, h3, code, pre {
        font-family: "Iosevka Aile", "IBM Plex Sans", "SFMono-Regular", monospace;
      }

      h1 {
        margin: 0;
        font-size: clamp(1.8rem, 4vw, 3rem);
        line-height: 1.02;
        letter-spacing: -0.03em;
      }

      .hero-copy {
        max-width: 700px;
        margin: 10px 0 0;
        font-size: 0.97rem;
        line-height: 1.6;
        color: var(--muted);
      }

      .quick-grid {
        display: grid;
        grid-template-columns: 1.2fr 0.8fr;
        gap: 12px;
        margin-top: 18px;
      }

      .panel {
        padding: 14px;
        border: 1px solid var(--line);
        border-radius: 14px;
        background: #fbfbfa;
      }

      .panel h3 {
        margin: 0 0 8px;
        font-size: 0.96rem;
      }

      .panel p {
        margin: 0 0 8px;
        color: var(--muted);
        line-height: 1.55;
        font-size: 0.92rem;
      }

      pre {
        margin: 0;
        padding: 10px 12px;
        overflow-x: auto;
        border: 1px solid #ebe8e2;
        border-radius: 12px;
        background: #f5f5f3;
        color: #171717;
        font-size: 0.87rem;
        line-height: 1.45;
      }

      .subhead {
        display: flex;
        align-items: center;
        justify-content: space-between;
        gap: 10px;
        margin: 22px 0 12px;
      }

      .subhead h2 {
        margin: 0;
        font-size: clamp(1.15rem, 2vw, 1.45rem);
      }

      .subhead p {
        margin: 0;
        color: var(--muted);
        font-size: 0.92rem;
      }

      .pill-link {
        display: inline-flex;
        align-items: center;
        gap: 8px;
        padding: 8px 11px;
        border-radius: 999px;
        border: 1px solid #f1d3ba;
        background: var(--accent-soft);
        text-decoration: none;
        font-size: 0.86rem;
        color: #8a3b00;
      }

      .products {
        display: grid;
        gap: 12px;
      }

      .product-card {
        padding: 14px 16px;
        border: 1px solid var(--line);
        border-radius: 16px;
        background: var(--panel);
      }

      .product-head {
        display: flex;
        align-items: center;
        justify-content: space-between;
        gap: 10px;
      }

      .product-head h2 {
        margin: 0;
        font-size: 1.05rem;
      }

      .version-badge {
        flex: none;
        padding: 5px 8px;
        border-radius: 999px;
        background: var(--accent-soft);
        font-size: 0.78rem;
        font-weight: 700;
        color: #8a3b00;
      }

      .product-desc {
        margin: 8px 0 0;
        color: var(--muted);
        line-height: 1.45;
        font-size: 0.92rem;
      }

      .meta-grid {
        display: grid;
        grid-template-columns: repeat(2, minmax(0, 1fr));
        gap: 8px;
        margin: 12px 0;
      }

      .meta-grid div {
        padding: 9px 10px;
        border-radius: 12px;
        background: #fbfbfa;
        border: 1px solid var(--line);
      }

      .meta-grid dt {
        margin-bottom: 4px;
        color: var(--muted);
        font-size: 0.72rem;
        text-transform: uppercase;
        letter-spacing: 0.08em;
      }

      .meta-grid dd {
        margin: 0;
        overflow-wrap: anywhere;
        font-size: 0.9rem;
      }

      .command-row {
        display: grid;
        grid-template-columns: 56px 1fr;
        gap: 8px;
        align-items: start;
        margin-top: 8px;
      }

      .command-label {
        display: inline-flex;
        align-items: center;
        height: 34px;
        margin: 0;
        color: var(--muted);
        font-size: 0.8rem;
      }

      footer {
        margin-top: 18px;
        padding: 8px 0 0;
        color: var(--muted);
        font-size: 0.84rem;
      }

      @media (max-width: 760px) {
        .page {
          width: min(100vw - 20px, 1120px);
          padding-top: 14px;
        }

        .hero {
          padding: 16px;
          border-radius: 16px;
        }

        .quick-grid,
        .meta-grid {
          grid-template-columns: 1fr;
        }

        .subhead {
          flex-direction: column;
          align-items: flex-start;
        }

        .command-row {
          grid-template-columns: 1fr;
        }

        .command-label {
          height: auto;
        }
      }
    </style>
  </head>
  <body>
    <main class="page">
      <section class="hero">
        <p class="eyebrow">Reusable Flatpak Remote</p>
        <h1>One remote. Small surface area.</h1>
        <p class="hero-copy">
          $(html_escape "${REMOTE_COMMENT}") Add the remote once, then install any package below by app ID.
        </p>
        <div class="quick-grid">
          <section class="panel">
            <h3>Add the remote</h3>
            <p>Run once per machine.</p>
            <pre><code>flatpak remote-add --if-not-exists $(command_escape "${REMOTE_NAME}") $(command_escape "${REMOTE_FILE_URL}")</code></pre>
          </section>
          <section class="panel">
            <h3>Links</h3>
            <p>Remote metadata and raw repo.</p>
            <p><a class="pill-link" href="$(html_escape "${REMOTE_FILE_URL}")">Open .flatpakrepo</a></p>
            <p><a class="pill-link" href="$(html_escape "${REMOTE_URL}")">Browse OSTree repo</a></p>
          </section>
        </div>
      </section>

      <section>
        <div class="subhead">
          <div>
            <h2>Package List</h2>
            <p>Compact install targets from tracked upstream releases.</p>
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
