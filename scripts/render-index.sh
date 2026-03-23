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

attr_escape() {
  local text
  text="$(html_escape "${1:-}")"
  text="${text//\"/&quot;}"
  text="${text//\'/&#39;}"
  printf '%s' "${text}"
}

command_escape() {
  html_escape "$1"
}

products_html=""
remote_cmd="flatpak remote-add --if-not-exists ${REMOTE_NAME} ${REMOTE_FILE_URL}"
remote_file_name="${REMOTE_FILE_URL##*/}"

products_html+=$(cat <<EOF
        <article class="file-row">
          <div class="file-main">
            <div class="file-name-wrap">
              <a class="file-name" href="$(html_escape "${REMOTE_FILE_URL}")">$(html_escape "${remote_file_name}")</a>
              <span class="version-badge">remote</span>
            </div>
            <p class="file-desc">Remote definition file for $(html_escape "${REMOTE_TITLE}"). Add it once, then install any package from this repository.</p>
          </div>
          <div class="file-actions">
            <button class="copy-button" type="button" data-copy="$(attr_escape "${remote_cmd}")">Copy install</button>
          </div>
          <div class="command-preview">
            <code>$(command_escape "${remote_cmd}")</code>
          </div>
        </article>
EOF
)

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
  ref_file="${APP_ID}.flatpakref"
  ref_url="${REMOTE_FILE_URL%/*}/refs/${APP_ID}.flatpakref"
  install_cmd="flatpak install ${ref_url}"

  products_html+=$(cat <<EOF
        <article class="file-row">
          <div class="file-main">
            <div class="file-name-wrap">
              <a class="file-name" href="$(html_escape "${ref_url}")">$(html_escape "${ref_file}")</a>
              <span class="version-badge">$(html_escape "${version}")</span>
            </div>
            <p class="file-desc">$(html_escape "${TITLE}") · $(html_escape "${DESCRIPTION:-No description available.}")</p>
          </div>
          <div class="file-actions">
            <button class="copy-button" type="button" data-copy="$(attr_escape "${install_cmd}")">Copy install</button>
          </div>
          <div class="command-preview">
            <code>$(command_escape "${install_cmd}")</code>
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
        --bg: #f3efe7;
        --panel: #ffffff;
        --ink: #171717;
        --muted: #666;
        --line: #ddd2c4;
        --accent: #9a3412;
        --accent-soft: #fde9dc;
        --button: #111827;
        --button-hover: #1f2937;
        --button-text: #fffdf8;
      }

      * { box-sizing: border-box; }

      body {
        margin: 0;
        color: var(--ink);
        background:
          radial-gradient(circle at top left, rgba(154, 52, 18, 0.08), transparent 28%),
          linear-gradient(180deg, #f7f1e8 0%, var(--bg) 100%);
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
        width: min(1060px, calc(100vw - 28px));
        margin: 0 auto;
        padding: 22px 0 40px;
      }

      .hero {
        padding: 24px 26px;
        border: 1px solid var(--line);
        border-radius: 24px;
        background:
          linear-gradient(135deg, rgba(255, 255, 255, 0.96), rgba(255, 247, 240, 0.98));
        box-shadow: 0 14px 40px rgba(73, 43, 24, 0.08);
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
        grid-template-columns: repeat(2, minmax(0, 1fr));
        gap: 12px;
        margin-top: 18px;
      }

      .panel {
        padding: 16px;
        border: 1px solid var(--line);
        border-radius: 18px;
        background: rgba(255, 255, 255, 0.78);
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
        border: 1px solid #e6dbcf;
        border-radius: 12px;
        background: #fffaf5;
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
        gap: 10px;
      }

      .file-row {
        display: grid;
        grid-template-columns: minmax(0, 1.6fr) auto minmax(0, 1.3fr);
        gap: 14px;
        align-items: center;
        padding: 14px 16px;
        border: 1px solid var(--line);
        border-radius: 18px;
        background: rgba(255, 255, 255, 0.9);
        box-shadow: 0 8px 18px rgba(73, 43, 24, 0.04);
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

      .file-main {
        min-width: 0;
      }

      .file-name-wrap {
        display: flex;
        flex-wrap: wrap;
        align-items: center;
        gap: 8px;
      }

      .file-name {
        font-family: "Iosevka Aile", "IBM Plex Sans", "SFMono-Regular", monospace;
        font-size: 1rem;
        font-weight: 700;
        overflow-wrap: anywhere;
      }

      .file-desc {
        margin: 7px 0 0;
        color: var(--muted);
        line-height: 1.45;
        font-size: 0.92rem;
      }

      .file-actions {
        display: flex;
        align-items: center;
      }

      .copy-button {
        border: 0;
        border-radius: 999px;
        padding: 10px 14px;
        background: var(--button);
        color: var(--button-text);
        font: inherit;
        font-size: 0.88rem;
        font-weight: 700;
        cursor: pointer;
        transition: transform 0.12s ease, background 0.12s ease;
      }

      .copy-button:hover {
        background: var(--button-hover);
        transform: translateY(-1px);
      }

      .copy-button.copied {
        background: var(--accent);
      }

      .command-preview {
        min-width: 0;
        padding: 10px 12px;
        border: 1px solid #e6dbcf;
        border-radius: 14px;
        background: #fffaf5;
        overflow-x: auto;
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
        .file-row {
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
        <h1>Files on the left. Install on the right.</h1>
        <p class="hero-copy">
          $(html_escape "${REMOTE_COMMENT}") Pick a file below, then copy the exact one-line install command you want to run.
        </p>
        <div class="quick-grid">
          <section class="panel">
            <h3>Remote File</h3>
            <p><a class="pill-link" href="$(html_escape "${REMOTE_FILE_URL}")">$(html_escape "${REMOTE_FILE_URL##*/}")</a></p>
            <pre><code>$(command_escape "${remote_cmd}")</code></pre>
          </section>
          <section class="panel">
            <h3>Repository</h3>
            <p>Remote name: <code>$(html_escape "${REMOTE_NAME}")</code></p>
            <p><a class="pill-link" href="$(html_escape "${REMOTE_HOMEPAGE}")">Repository owner</a></p>
            <p><a class="pill-link" href="$(html_escape "${REMOTE_URL}")">Browse OSTree repo</a></p>
          </section>
        </div>
      </section>

      <section>
        <div class="subhead">
          <div>
            <h2>File List</h2>
            <p>Left side is the downloadable file. Right side is the command you can copy directly.</p>
          </div>
          <button class="copy-button" type="button" data-copy="$(attr_escape "${remote_cmd}")">Copy remote add</button>
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
    <script>
      document.querySelectorAll('.copy-button').forEach((button) => {
        button.addEventListener('click', async () => {
          const text = button.dataset.copy || '';
          if (!text) {
            return;
          }

          try {
            await navigator.clipboard.writeText(text);
            const original = button.textContent;
            button.textContent = 'Copied';
            button.classList.add('copied');
            window.setTimeout(() => {
              button.textContent = original;
              button.classList.remove('copied');
            }, 1200);
          } catch (error) {
            console.error('Copy failed', error);
          }
        });
      });
    </script>
  </body>
</html>
EOF

echo "Wrote ${OUTPUT_PATH}"
