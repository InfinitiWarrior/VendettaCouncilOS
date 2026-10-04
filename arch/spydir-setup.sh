#!/bin/sh
# Vendetta Council OS (Arch) — preinstall the spydirbyte security toolkit into
# /opt/spydir with one shared Python venv, each tool exposed as /usr/local/bin/<name>.
# Ported verbatim from the Debian 0130 hook (git/python/node are all present).
# App-menu entries are static (copied from the Debian tree by copy-shared-assets.sh);
# web-app launchers use /usr/local/bin/spydir-webapp.
set -e
BASE=/opt/spydir
VENV=$BASE/venv
GH=https://github.com/spydirbyte

TOOLS="spy-crack spy-geoint spy-kernel-triage spy-osint-suite spy-privacy-pulse
spy-recon-mapper spy-threat-hunt spy-trail spy-vector spy-wraith spy-xray"

install -d "$BASE"
# `python3 -m venv` fails in some build chroots ("Unable to determine path to
# the running Python interpreter") when launched via a symlink without /proc —
# use the resolved concrete binary, and make sure /proc is mounted.
mountpoint -q /proc 2>/dev/null || mount -t proc proc /proc 2>/dev/null || true
PY=$(readlink -f "$(command -v python3)" 2>/dev/null); [ -x "$PY" ] || PY=/usr/bin/python3
# --system-site-packages: Pillow has no wheel for Arch's Python yet and won't
# compile here, so the venv borrows pacman's python-pillow.
"$PY" -m venv --system-site-packages "$VENV" || python3 -m venv --system-site-packages "$VENV"
"$VENV/bin/pip" install --no-input --quiet --upgrade pip || true

for name in $TOOLS; do
	dir="$BASE/$name"
	git clone --depth 1 "$GH/$name.git" "$dir" 2>&1 || { echo "W: clone failed, skipping $name"; continue; }
	# Pillow comes from pacman (see above); a pinned Pillow here would be built
	# from source and take the tool's other deps down with it.
	[ -f "$dir/requirements.txt" ] && \
		grep -vi '^pillow' "$dir/requirements.txt" | \
		"$VENV/bin/pip" install --no-input --quiet -r /dev/stdin \
			|| echo "W: deps failed for $name (installing anyway)"
	entry=""
	for e in cli.py app.py run.py; do [ -f "$dir/$e" ] && { entry=$e; break; }; done
	[ -n "$entry" ] || { echo "W: no entry point for $name, skipping wrapper"; continue; }
	cat > "/usr/local/bin/$name" <<EOF
#!/bin/sh
exec "$VENV/bin/python" "$dir/$entry" "\$@"
EOF
	chmod +x "/usr/local/bin/$name"
done

if git clone --depth 1 "$GH/spy-webster.git" "$BASE/spy-webster" 2>/dev/null; then
	( cd "$BASE/spy-webster" && npm ci --silent && npm run build --if-present ) \
		&& cat > /usr/local/bin/spy-webster <<EOF
#!/bin/sh
exec node "$BASE/spy-webster/dist/index.js" "\$@"
EOF
	[ -f /usr/local/bin/spy-webster ] && chmod +x /usr/local/bin/spy-webster
else
	echo "W: spy-webster clone/build failed, skipping"
fi
