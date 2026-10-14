#!/usr/bin/env bash
set -eo pipefail

PORT="${PORT:-80}"
if grep -q '^Listen 80$' /etc/apache2/ports.conf; then
  sed -i "s/^Listen 80$/Listen ${PORT}/" /etc/apache2/ports.conf
fi
if ! grep -q "^Listen ${PORT}$" /etc/apache2/ports.conf; then
  echo "Listen ${PORT}" >> /etc/apache2/ports.conf
fi
sed -i "s/\*:80/*:${PORT}/g" /etc/apache2/sites-available/000-default.conf

rm -f /etc/apache2/mods-enabled/mpm_event.* /etc/apache2/mods-enabled/mpm_worker.* 2>/dev/null || true
a2enmod mpm_prefork >/dev/null 2>&1 || true

seed() {
  if [ -z "${SEED_SQL:-}" ]; then return 0; fi
  if [ -z "${MYSQLHOST:-}" ]; then return 0; fi
  export MYSQL_PWD="${MYSQLPASSWORD:-}"
  local MYSQLARGS=(-h "$MYSQLHOST" -P "${MYSQLPORT:-3306}" -u "${MYSQLUSER:-root}")
  echo "[entrypoint] waiting for MySQL at ${MYSQLHOST}..."
  for _ in $(seq 1 60); do
    if mysql "${MYSQLARGS[@]}" -e "SELECT 1" >/dev/null 2>&1; then break; fi
    sleep 2
  done
  if [ -n "${MYSQLDATABASE:-}" ]; then
    mysql "${MYSQLARGS[@]}" -e "CREATE DATABASE IF NOT EXISTS \`${MYSQLDATABASE}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci" 2>/dev/null || true
  fi
  local DARGS=("${MYSQLARGS[@]}")
  if [ -n "${MYSQLDATABASE:-}" ]; then DARGS+=(-D "$MYSQLDATABASE"); fi
  local CHECK="SELECT 1 FROM ${SEED_CHECK_TABLE:-products} LIMIT 1"
  if [ "${SEED_FORCE:-0}" = "1" ] || ! mysql "${DARGS[@]}" -e "$CHECK" >/dev/null 2>&1; then
    echo "[entrypoint] seeding from ${SEED_SQL}"
    sed -e '/^CREATE DATABASE/d' -e '/^USE /d' "/var/www/html/${SEED_SQL}" | mysql "${DARGS[@]}" || echo "[entrypoint] WARN seeding failed (continuing)"
  else
    echo "[entrypoint] database already seeded, skipping"
  fi
}
seed

exec apache2-foreground
