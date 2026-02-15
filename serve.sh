#!/bin/bash
set -e

# serve.sh - Deploy xallt.github.io to production with nginx + HTTPS
# This script builds the Jekyll site and sets up nginx to serve it

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/_site"
NGINX_HTTP_CONFIG="/etc/nginx/sites-available/blog.xallt.online.http.conf"
NGINX_HTTPS_CONFIG="/etc/nginx/sites-available/blog.xallt.online.https.conf"
DOMAIN="blog.xallt.online"
EMAIL="mitya.shabat@gmail.com"

echo "🚀 Deploying xallt.github.io..."

# 1. Install Ruby dependencies
echo "📦 Installing Ruby dependencies..."
cd "$SCRIPT_DIR"
bundle install

# 2. Build the site
echo "🔨 Building Jekyll site..."
bundle exec jekyll build

# 3. Copy to /var/www
echo "📂 Copying files to /var/www..."
sudo mkdir -p /var/www/$DOMAIN
sudo cp -r "$BUILD_DIR"/* /var/www/$DOMAIN/
sudo chown -R www-data:www-data /var/www/$DOMAIN

# 4. Setup HTTP nginx config
echo "🌐 Setting up nginx HTTP configuration..."
sudo tee "$NGINX_HTTP_CONFIG" > /dev/null <<EOF
server {
    listen 80;
    server_name $DOMAIN;

    # Redirect to HTTPS
    return 301 https://\$server_name\$request_uri;
}
EOF

# 5. Get SSL certificate with certbot if not exists
if [ ! -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
    echo "🔐 Getting SSL certificate for $DOMAIN..."
    sudo apt-get install -y certbot python3-certbot-nginx 2>/dev/null || true
    sudo certbot certonly --nginx -d $DOMAIN --non-interactive --agree-tos --email $EMAIL --redirect
fi

# 6. Setup HTTPS nginx config
echo "🔒 Setting up nginx HTTPS configuration..."
sudo tee "$NGINX_HTTPS_CONFIG" > /dev/null <<EOF
server {
    listen 443 ssl http2;
    server_name $DOMAIN;

    # SSL certificates
    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;

    # SSL configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # HSTS
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    # Serve static files from /var/www
    root /var/www/$DOMAIN;
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

# 7. Enable nginx configs
sudo ln -sf "$NGINX_HTTP_CONFIG" /etc/nginx/sites-enabled/
sudo ln -sf "$NGINX_HTTPS_CONFIG" /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx

# 8. Show status
echo ""
echo "✅ Deployment complete!"
echo ""
echo "🌐 Your site is live at: https://$DOMAIN"
echo ""
echo "Useful commands:"
echo "  sudo nginx -t                          # Test nginx config"
echo "  sudo systemctl reload nginx            # Reload nginx"
echo "  sudo certbot renew                      # Renew SSL certificate"
echo "  ./serve.sh                              # Re-deploy after changes"
