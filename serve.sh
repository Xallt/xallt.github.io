#!/bin/bash
set -e

# serve.sh - Deploy xallt.github.io to production with nginx
# This script builds the Jekyll site and sets up nginx to serve it

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/_site"
NGINX_CONFIG="/etc/nginx/sites-available/blog.xallt.online.conf"

echo "🚀 Deploying xallt.github.io..."

# 1. Install Ruby dependencies
echo "📦 Installing Ruby dependencies..."
cd "$SCRIPT_DIR"
bundle install

# 2. Build the site
echo "🔨 Building Jekyll site..."
bundle exec jekyll build

# 3. Setup nginx if not exists
if [ ! -f "$NGINX_CONFIG" ]; then
    echo "🌐 Setting up nginx configuration..."
    sudo tee "$NGINX_CONFIG" > /dev/null <<EOF
server {
    listen 80;
    server_name blog.xallt.online;

    # Serve static files from Jekyll build output
    root $BUILD_DIR;
    index index.html;

    # Try to serve static files first, fallback to index.html for SPA routing
    location / {
        try_files \$uri \$uri/ /index.html;
    }

    # Enable gzip compression
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;

    # Cache static assets
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
EOF

    sudo ln -sf "$NGINX_CONFIG" /etc/nginx/sites-enabled/
    sudo nginx -t && sudo systemctl reload nginx
    echo "✅ Nginx configured"
else
    echo "ℹ️  Nginx config already exists"
    # Update the root path in case it changed
    sudo sed -i "s|root .*;|root $BUILD_DIR;|" "$NGINX_CONFIG"
    sudo nginx -t && sudo systemctl reload nginx
fi

# 4. Show status
echo ""
echo "✅ Deployment complete!"
echo ""
echo "🌐 Your site is live at: http://blog.xallt.online"
echo ""
echo "Useful commands:"
echo "  sudo nginx -t                          # Test nginx config"
echo "  sudo systemctl reload nginx            # Reload nginx"
echo "  ./serve.sh                              # Re-deploy after changes"
