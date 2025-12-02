#!/bin/bash
set -e

# Determine script directory (absolute path)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Nginx repo root = one directory up
NGINX_DIR="$SCRIPT_DIR/../nginx"

# Repo paths
REPO_NGINX_CONF="$NGINX_DIR/nginx.conf"
REPO_SITES_ENABLED_DIR="$NGINX_DIR/sites-enabled"

# System paths
SYSTEM_NGINX_CONF="/etc/nginx/nginx.conf"
SYSTEM_SITES_ENABLED="/etc/nginx/sites-enabled"

echo "-------------------------------------------"
echo "🔧 Setting up Nginx from GitHub repo"
echo "Script directory: $SCRIPT_DIR"
echo "Repo nginx dir:   $NGINX_DIR"
echo "Repo sites dir:   $REPO_SITES_ENABLED_DIR"
echo "-------------------------------------------"

# 1. Backup system nginx.conf if not already symlinked
if [ -f "$SYSTEM_NGINX_CONF" ] && [ ! -L "$SYSTEM_NGINX_CONF" ]; then
  echo "📦 Backing up system nginx.conf"
  sudo mv "$SYSTEM_NGINX_CONF" "$SYSTEM_NGINX_CONF.backup"
fi

# 2. Symlink repo nginx.conf
if [ ! -L "$SYSTEM_NGINX_CONF" ]; then
  echo "🔗 Linking nginx.conf"
  sudo ln -s "$REPO_NGINX_CONF" "$SYSTEM_NGINX_CONF"
else
  echo "✔ nginx.conf already symlinked"
fi

# Ensure /etc/nginx/sites-enabled exists
sudo mkdir -p "$SYSTEM_SITES_ENABLED"

# 3. Symlink all .conf files from repo → system
echo "🔗 Linking site-enabled configs..."

shopt -s nullglob # prevent literal '*.conf'
FILES=("$REPO_SITES_ENABLED_DIR"/*.conf)

if [ ${#FILES[@]} -eq 0 ]; then
  echo "❌ ERROR: No .conf files found inside:"
  echo "   $REPO_SITES_ENABLED_DIR"
  exit 1
fi

for FILE in "${FILES[@]}"; do
  BASENAME=$(basename "$FILE")
  TARGET="$SYSTEM_SITES_ENABLED/$BASENAME"

  if [ -L "$TARGET" ] && [ -e "$TARGET" ]; then
    echo "✔ Already linked: $BASENAME"
  else
    echo "🔗 (Re)linking: $BASENAME"
    sudo rm -f "$TARGET"
    sudo ln -s "$FILE" "$TARGET"
  fi

done

# Validate Nginx config
echo "-------------------------------------------"
echo "🔍 Testing Nginx configuration..."
sudo nginx -t

# Reload
echo "🔄 Reloading Nginx..."
sudo systemctl reload nginx

echo "🎉 Setup complete!"
echo "Nginx is now using your Git-controlled configuration."
echo "-------------------------------------------"
