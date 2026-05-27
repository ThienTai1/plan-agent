#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
ENV_FILE="$ROOT_DIR/.env"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Missing .env file. Copy .env.example to .env first."
  exit 1
fi

docker compose -f "$ROOT_DIR/infra/docker-compose.yml" up --build -d
