#!/bin/sh
set -e
BASE=/opt/spydir
VENV=$BASE/venv
GH=https://github.com/spydirbyte

TOOLS="spy-crack spy-geoint spy-kernel-triage spy-osint-suite spy-privacy-pulse
spy-recon-mapper spy-threat-hunt spy-trail spy-vector spy-wraith spy-xray"

install -d "$BASE"
mountpoint -q /proc 2>/dev/null || mount -t proc proc /proc 2>/dev/null || true
PY=$(readlink -f "$(command -v python3)" 2>/dev/null); [ -x "$PY" ] || PY=/usr/bin/python3
"$PY" -m venv --system-site-packages "$VENV" || python3 -m venv --system-site-packages "$VENV"
"$VENV/bin/pip" install --no-input --quiet --upgrade pip || true
if "$VENV/bin/python" -c 'import PIL' 2>/dev/null; then SKIP='^pillow'; else SKIP='a^'; fi

for name in $TOOLS; do
	dir="$BASE/$name"
	git clone --depth 1 "$GH/$name.git" "$dir" 2>&1 || { echo "W: clone failed, skipping $name"; continue; }
	[ -f "$dir/requirements.txt" ] && \
		grep -vi "$SKIP" "$dir/requirements.txt" | \
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
