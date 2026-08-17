#!/bin/sh

# Re-seed the default logo/favicon/PWA icons if they aren't already present.
# /tmp/img is baked into the image (not volume-mounted), so this never
# overwrites a custom logo the backend has written into the shared
# public/img volume.
cp -rn /tmp/img/* /opt/app/frontend/public/img

cd /opt/app/frontend
PORT=${PORT:-3000} HOSTNAME=0.0.0.0 exec node server.js
