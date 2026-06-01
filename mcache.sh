#!/usr/bin/env bash
set -euo pipefail

docker compose exec moodle php admin/cli/purge_caches.php