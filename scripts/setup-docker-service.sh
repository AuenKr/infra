#!/bin/bash
set -e

# Determine script directory (absolute path)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DOCKER_DIR="$SCRIPT_DIR/../services"

echo "-------------------------------------------"
echo "🔧 Setting up Docker services from GitHub repo"
echo "Script directory: $SCRIPT_DIR"
echo "Repo Docker dir:   $DOCKER_DIR"
echo "-------------------------------------------"

# Check docker exists
if ! command -v docker >/dev/null 2>&1; then
  echo "❌ Docker is not installed or not in PATH."
  exit 1
fi

if ! command -v docker-compose >/dev/null 2>&1 && ! docker compose version >/dev/null 2>&1; then
  echo "❌ Docker Compose not available (neither docker-compose nor docker compose)."
  exit 1
fi

# Go to each directory present in DOCKER_DIR
echo "🔍 Scanning directories inside: $DOCKER_DIR"

if [ ! -d "$DOCKER_DIR" ]; then
  echo "❌ Directory not found: $DOCKER_DIR"
  exit 1
fi

# Iterate over each directory, check docker-compose.yaml exist, if exists run docker compose up -d
for dir in "$DOCKER_DIR"/*; do
  if [ -d "$dir" ]; then
    echo ""
    echo "-------------------------------------------"
    echo "📁 Checking: $(basename "$dir")"

    # Check for docker-compose or compose.yaml variants
    if [ -f "$dir/docker-compose.yml" ] || [ -f "$dir/docker-compose.yaml" ]; then
      echo "🟢 Compose file found. Starting service..."

      # Use 'docker compose' if available, else fallback to docker-compose
      if docker compose version >/dev/null 2>&1; then
        (cd "$dir" && docker compose up -d)
      else
        (cd "$dir" && docker-compose up -d)
      fi

      echo "✔️ Service started: $(basename "$dir")"
    else
      echo "⚠️ No docker-compose.yml found. Skipping."
    fi
  fi
done

echo ""
echo "-------------------------------------------"
echo "🏁 All services processed!"
echo "-------------------------------------------"
