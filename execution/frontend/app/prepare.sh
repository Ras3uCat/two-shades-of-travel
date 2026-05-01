#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# prepare.sh — Replace CLIENT_* tokens in web/ files and generate sitemap.xml.
#
# Called automatically by deliver.sh before the Flutter build.
# Can also be run standalone after updating client.json:
#   ./prepare.sh
#
# Template files (*.tpl) are the source of truth — never edit the generated files
# directly. Re-running prepare.sh will overwrite them from the templates.
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLIENT_JSON="$SCRIPT_DIR/client.json"
WEB_DIR="$SCRIPT_DIR/web"

green() { printf "\033[32m✅ %s\033[0m\n" "$*"; }
warn()  { printf "\033[33m⚠  %s\033[0m\n" "$*"; }
info()  { printf "   %s\n" "$*"; }

if [[ ! -f "$CLIENT_JSON" ]]; then
  printf "\033[31m❌ client.json not found — cannot prepare web assets.\033[0m\n" >&2
  exit 1
fi

python3 - "$CLIENT_JSON" "$WEB_DIR" << 'PYEOF'
import json, sys, os

client_json = sys.argv[1]
web_dir     = sys.argv[2]

with open(client_json) as f:
    c = json.load(f)

client_name = c.get('CLIENT_NAME', '')
site_url    = c.get('SITE_URL', '').rstrip('/')
modules_str = c.get('MODULES', '')
modules     = set(m.strip() for m in modules_str.split(',') if m.strip())

# SHORT_NAME: optional field, defaults to CLIENT_NAME truncated to 12 chars
short_name  = c.get('SHORT_NAME', client_name[:12])

# HOURS_JSON: optional, defaults to empty array (no structured hours in JSON-LD)
hours_json  = c.get('HOURS_JSON', '[]')

replacements = {
    'CLIENT_NAME':          client_name,
    'CLIENT_SHORT_NAME':    short_name,
    'CLIENT_TITLE':         c.get('SEO_TITLE',       client_name),
    'CLIENT_DESCRIPTION':   c.get('SEO_DESCRIPTION', ''),
    'CLIENT_OG_IMAGE':      c.get('OG_IMAGE',        ''),
    'CLIENT_URL':           site_url,
    'CLIENT_PHONE':         c.get('PHONE',           ''),
    'CLIENT_STREET':        c.get('STREET',          ''),
    'CLIENT_CITY':          c.get('CITY',            ''),
    'CLIENT_STATE':         c.get('STATE',           ''),
    'CLIENT_ZIP':           c.get('ZIP',             ''),
    'CLIENT_COUNTRY':       c.get('COUNTRY',         ''),
    'CLIENT_HOURS_JSON':    hours_json,
    'CLIENT_COLOR_SURFACE': c.get('COLOR_SURFACE',   '000000'),
    'CLIENT_COLOR_PRIMARY': c.get('COLOR_PRIMARY',   'ffffff'),
}

def apply(content):
    for k, v in replacements.items():
        content = content.replace(k, v)
    return content

# ── Process .tpl → actual files ───────────────────────────────────────────────
templates = [
    ('index.html.tpl',    'index.html'),
    ('manifest.json.tpl', 'manifest.json'),
    ('robots.txt.tpl',    'robots.txt'),
]

for tpl_name, out_name in templates:
    tpl_path = os.path.join(web_dir, tpl_name)
    out_path = os.path.join(web_dir, out_name)
    if os.path.exists(tpl_path):
        with open(tpl_path) as f:
            content = f.read()
        with open(out_path, 'w') as f:
            f.write(apply(content))
        print(f'   ✅ {out_name}')
    else:
        print(f'   ⚠  {tpl_name} not found — skipping {out_name}')

# ── Generate sitemap.xml from enabled modules ─────────────────────────────────
def url_block(loc, freq, priority):
    return (
        f'  <url>\n'
        f'    <loc>{loc}</loc>\n'
        f'    <changefreq>{freq}</changefreq>\n'
        f'    <priority>{priority}</priority>\n'
        f'  </url>'
    )

blocks = [
    url_block(site_url + '/',        'weekly',  '1.0'),
    url_block(site_url + '/contact', 'monthly', '0.7'),
]

module_routes = [
    ('booking',      site_url + '/booking',      'weekly',  '0.9'),
    ('testimonials', site_url + '/testimonials', 'monthly', '0.6'),
    ('gallery',      site_url + '/gallery',      'weekly',  '0.7'),
    ('faq',          site_url + '/faq',          'monthly', '0.6'),
    ('blog',         site_url + '/blog',         'weekly',  '0.8'),
    ('events',       site_url + '/events',       'weekly',  '0.9'),
    ('shop',         site_url + '/shop',         'weekly',  '0.8'),
    ('services',     site_url + '/services',     'weekly',  '0.8'),
]

for mod, loc, freq, pri in module_routes:
    if mod in modules:
        blocks.append(url_block(loc, freq, pri))

# ── Slugify Helper ───────────────────────────────────────────────────────────
import re
def slugify(text):
    if not text: return ""
    text = text.lower().strip()
    text = re.sub(r'[^a-z0-9\s-]', '', text)
    text = re.sub(r'\s+', '-', text)
    text = re.sub(r'-+', '-', text)
    return text

# ── Fetch published blog post slugs from Supabase REST API ───────────────────
supabase_url  = c.get('SUPABASE_URL', '').rstrip('/')
supabase_anon = c.get('SUPABASE_ANON_KEY', '')

if site_url and supabase_url and supabase_anon:
    try:
        import urllib.request
        import json as _json

        # 1. Blog Posts
        if 'blog' in modules:
            rest_url = (
                supabase_url
                + '/rest/v1/blog_posts'
                + '?published_at=not.is.null'
                + '&select=slug'
                + '&order=published_at.desc'
            )
            req = urllib.request.Request(
                rest_url,
                headers={
                    'apikey': supabase_anon,
                    'Authorization': 'Bearer ' + supabase_anon,
                },
            )
            with urllib.request.urlopen(req, timeout=10) as resp:
                posts = _json.loads(resp.read())
            for post in posts:
                slug = post.get('slug', '').strip()
                if slug:
                    blocks.append(url_block(site_url + '/blog/' + slug, 'weekly', '0.7'))
            print(f'   ✅ sitemap: added {len(posts)} blog post(s)')

        # 2. Services
        if 'services' in modules or 'booking' in modules:
            rest_url = (
                supabase_url
                + '/rest/v1/services'
                + '?is_active=eq.true'
                + '&select=name'
            )
            req = urllib.request.Request(
                rest_url,
                headers={
                    'apikey': supabase_anon,
                    'Authorization': 'Bearer ' + supabase_anon,
                },
            )
            with urllib.request.urlopen(req, timeout=10) as resp:
                rows = _json.loads(resp.read())
            for row in rows:
                name = row.get('name', '').strip()
                if name:
                    slug = slugify(name)
                    blocks.append(url_block(site_url + '/services/' + slug, 'weekly', '0.7'))
            print(f'   ✅ sitemap: added {len(rows)} service page(s)')

    except Exception as e:
        print(f'   ⚠  sitemap details skipped (Supabase unreachable): {e}')
else:
    print('   ⚠  sitemap details skipped (SUPABASE_URL or SUPABASE_ANON_KEY not set)')

sitemap = (
    '<?xml version="1.0" encoding="UTF-8"?>\n'
    '<!-- Generated by prepare.sh — re-run after publishing new blog posts -->\n'
    '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n'
    + '\n'.join(blocks) + '\n'
    + '</urlset>\n'
)

with open(os.path.join(web_dir, 'sitemap.xml'), 'w') as f:
    f.write(sitemap)
print('   ✅ sitemap.xml (modules: ' + ', '.join(sorted(modules)) + ')')

PYEOF

green "Web assets prepared"

# ── Favicon + PWA icon generation ─────────────────────────────────────────────
LOGO_URL_VAL=$(python3 -c "import json; d=json.load(open('$CLIENT_JSON')); print(d.get('LOGO_URL',''))" 2>/dev/null || echo "")
COLOR_SURFACE_VAL=$(python3 -c "import json; d=json.load(open('$CLIENT_JSON')); print(d.get('COLOR_SURFACE','000000'))" 2>/dev/null || echo "000000")
CLIENT_SLUG_VAL=$(python3 -c "import json; d=json.load(open('$CLIENT_JSON')); print(d.get('CLIENT_SLUG',''))" 2>/dev/null || echo "")

if [[ -n "$LOGO_URL_VAL" && "$LOGO_URL_VAL" != "FILL_IN" ]]; then
  if command -v convert &>/dev/null; then
    TMP_LOGO=$(mktemp /tmp/logo_XXXXXX)
    if curl -sf "$LOGO_URL_VAL" -o "$TMP_LOGO"; then
      mkdir -p "$WEB_DIR/icons"
      convert "$TMP_LOGO" -resize 32x32     "$WEB_DIR/favicon.png"
      convert "$TMP_LOGO" -resize 192x192   "$WEB_DIR/icons/Icon-192.png"
      convert "$TMP_LOGO" -resize 512x512   "$WEB_DIR/icons/Icon-512.png"
      convert "$TMP_LOGO" -resize 154x154 -gravity center \
        -background "#$COLOR_SURFACE_VAL" -extent 192x192 "$WEB_DIR/icons/Icon-maskable-192.png"
      convert "$TMP_LOGO" -resize 410x410 -gravity center \
        -background "#$COLOR_SURFACE_VAL" -extent 512x512 "$WEB_DIR/icons/Icon-maskable-512.png"
      green "Favicons + PWA icons generated from LOGO_URL"
      [[ -n "$CLIENT_SLUG_VAL" ]] && touch "/tmp/.favicon_generated_${CLIENT_SLUG_VAL}"
    else
      warn "Could not download LOGO_URL — favicons not replaced."
    fi
    rm -f "$TMP_LOGO"
  else
    warn "ImageMagick not found — favicons not replaced. Install: brew install imagemagick"
  fi
else
  warn "LOGO_URL not set — favicons not replaced."
fi
