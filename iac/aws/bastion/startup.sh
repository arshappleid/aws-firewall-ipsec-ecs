#!/bin/bash
# Update system
apt-get update -y
apt-get install -y postgresql-client

# Install dependencies
apt-get install -y apt-transport-https software-properties-common wget

# Add Grafana GPG key and repo
mkdir -p /etc/apt/keyrings
wget -q -O /etc/apt/keyrings/grafana.key https://apt.grafana.com/gpg.key
echo "deb [signed-by=/etc/apt/keyrings/grafana.key] https://apt.grafana.com stable main" | tee /etc/apt/sources.list.d/grafana.list

# Install Grafana
apt-get update -y
apt-get install -y grafana

# Enable on restart
systemctl enable grafana-server

# Configure Grafana database (PostgreSQL) in grafana.ini
sed -i '/^\[database\]/,/^\[/{
  s/^;*\s*type\s*=.*/type = postgres/
  s/^;*\s*host\s*=.*/host = ${rds_endpoint}/
  s/^;*\s*name\s*=.*/name = grafana/
  s/^;*\s*user\s*=.*/user = company_admin/
  s/^;*\s*password\s*=.*/password = ${grafana_db_password}/
  s/^;*\s*ssl_mode\s*=.*/ssl_mode = require/
}' /etc/grafana/grafana.ini

# Configure Grafana admin password in [security] section
sed -i '/^\[security\]/,/^\[/{
  s/^;*\s*admin_password\s*=.*/admin_password = ${grafana_admin_password}/
}' /etc/grafana/grafana.ini

# Bind Grafana to localhost only — Nginx serves it at /grafana on :443
sed -i '/^\[server\]/,/^\[/{
  s/^;*\s*http_addr\s*=.*/http_addr = 127.0.0.1/
  s/^;*\s*http_port\s*=.*/http_port = 3000/
  s/^;*\s*root_url\s*=.*/root_url = %(protocol)s:\/\/%(domain)s:\/grafana\//
  s/^;*\s*serve_from_sub_path\s*=.*/serve_from_sub_path = true/
}' /etc/grafana/grafana.ini

systemctl start grafana-server

grafana cli plugins install grafana-athena-datasource

systemctl restart grafana-server

# ─── Nginx reverse proxy for OpenSearch ───────────────────────────────────────
apt-get install -y nginx

# Install Certbot with Route 53 DNS plugin
apt-get install -y certbot python3-certbot-dns-route53

# Obtain a Let's Encrypt certificate via DNS validation (no port 80 needed)
certbot certonly --dns-route53 -d bastion.datecompany.com --non-interactive --agree-tos --email prabhmeet@datecompany.com

## Wazuh Installation (loaded from wazuh_install.sh)
# Skipped in bootstrap. Run manually later if needed.

# Write the final Nginx config with the cert
cat > /etc/nginx/sites-available/opensearch <<'NGINX_CONF'
server {
    listen 80;
  server_name bastion.datecompany.com;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
  server_name bastion.datecompany.com;

  ssl_certificate     /etc/letsencrypt/live/bastion.datecompany.com/fullchain.pem;
  ssl_certificate_key /etc/letsencrypt/live/bastion.datecompany.com/privkey.pem;

    # ── Wazuh Dashboard at /siem ──
    location /siem/ {
        proxy_pass http://127.0.0.1:5601/siem/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # WebSocket support for dashboard live updates
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }

    # ── Grafana at /grafana ──
    location /grafana/ {
        proxy_pass http://127.0.0.1:3000/grafana/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # WebSocket support for Grafana Live
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }

    location / {
        proxy_pass https://${opensearch_endpoint}:443;
        proxy_ssl_verify off;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_buffering off;
        proxy_request_buffering off;
    }
}
NGINX_CONF

ln -sf /etc/nginx/sites-available/opensearch /etc/nginx/sites-enabled/opensearch

rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl enable nginx && systemctl restart nginx

