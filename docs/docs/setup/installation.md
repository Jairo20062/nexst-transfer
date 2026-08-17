---
id: installation
---

# Installation

### Installation with Docker (recommended)

1. Download the `docker-compose.yml` file
2. Run `docker compose up -d`

The website is now listening on `http://localhost:3000`, have fun with Nexst Transfer!

### Installation with Portainer

1. In the **Stacks** menu, click the **Add stack** button
2. Give you stack a name (ex. nexsttransfer)
3. In the web editor, paste the content of the [docker-compose](https://github.com/smp46/pingvin-share-x/blob/main/docker-compose.yml) file.
4. Edit the external port and the environment variables (optional).
5. Click on **Deploy the stack**.

Your container is now listening on `http://localhost:<externalport>`, have fun with Nexst Transfer!

### Stand-alone Installation

Required tools:

- [Node.js](https://nodejs.org/en/download/) >= 22
- [Git](https://git-scm.com/downloads)
- [pm2](https://pm2.keymetrics.io/) for running Nexst Transfer in the background

```bash
git clone https://github.com/smp46/pingvin-share-x
cd pingvin-share-x

# Checkout the latest version
git fetch --tags && git checkout $(git describe --tags `git rev-list --tags --max-count=1`)

# Start the backend
cd backend
npm install
npm run build
pm2 start --name="nexst-transfer-backend" npm -- run prod

# Start the frontend
cd ../frontend
npm install
npm run build
API_URL=http://localhost:8080 # Set the URL of the backend, default: http://localhost:8080
pm2 start npm --name "nexst-transfer-frontend" -- run start
```

**Uploading Large Files**: By default, Nexst Transfer uses a built-in reverse proxy to reduce the installation steps. However, this reverse proxy is not optimized for uploading large files. If you wish to upload larger files, you can either use the Docker installation or set up your own reverse proxy. An example configuration for Caddy can be found in `./reverse-proxy/Caddyfile`.

The website is now listening on `http://localhost:3000`, have fun with Nexst Transfer!

### Alternative Deployments

Nexst Transfer can also be deployed via the following platforms:

#### Zenith

[![Deploy with Zenith](https://cdn.zenith.hosting/buttons/deploy-with-zenith.svg)](https://zenith.hosting/host/pingvin-share-x)

One-click managed Nexst Transfer.<br />
DISCLAIMER: A portion of each subscription goes to the Nexst Transfer project.

If you run a platform or know of a platform which supports deployments of Nexst Transfer, please open a PR and it can be added here.

