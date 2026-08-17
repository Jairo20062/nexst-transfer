#!/bin/sh
set -e

cd /opt/app/backend
./node_modules/.bin/prisma migrate deploy
node dist/prisma/seed/config.seed.js
exec node dist/src/main
