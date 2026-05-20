#!/bin/bash
## Wazuh Installation Script

apt-get install -y gnupg apt-transport-https
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --no-default-keyring --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import && chmod 644 /usr/share/keyrings/wazuh.gpg
echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | tee -a /etc/apt/sources.list.d/wazuh.list
apt-get update

## Wazuh Indexer Installation
apt-get install -y wazuh-indexer

# Configure Wazuh Indexer — bind to localhost
cat > /etc/wazuh-indexer/opensearch.yml <<'INDEXER_CONF'
network.host: "127.0.0.1"
node.name: "node-1"
cluster.initial_master_nodes:
  - "node-1"
plugins.security.ssl.transport.pemcert_filepath: /etc/wazuh-indexer/certs/wazuh-indexer.pem
plugins.security.ssl.transport.pemkey_filepath: /etc/wazuh-indexer/certs/wazuh-indexer-key.pem
plugins.security.ssl.transport.pemtrustedcas_filepath: /etc/wazuh-indexer/certs/root-ca.pem
plugins.security.ssl.http.enabled: true
plugins.security.ssl.http.pemcert_filepath: /etc/wazuh-indexer/certs/wazuh-indexer.pem
plugins.security.ssl.http.pemkey_filepath: /etc/wazuh-indexer/certs/wazuh-indexer-key.pem
plugins.security.ssl.http.pemtrustedcas_filepath: /etc/wazuh-indexer/certs/root-ca.pem
plugins.security.allow_default_init_securityindex: true
compatibility.override_main_response_version: true
INDEXER_CONF

# Generate self-signed certs for the indexer
mkdir -p /etc/wazuh-indexer/certs
openssl req -x509 -batch -nodes -days 3650 -newkey rsa:2048 \
  -keyout /etc/wazuh-indexer/certs/root-ca-key.pem \
  -out /etc/wazuh-indexer/certs/root-ca.pem \
  -subj "/CN=Wazuh Root CA"
openssl req -batch -nodes -newkey rsa:2048 \
  -keyout /etc/wazuh-indexer/certs/wazuh-indexer-key.pem \
  -out /etc/wazuh-indexer/certs/wazuh-indexer.csr \
  -subj "/CN=wazuh-indexer"
openssl x509 -req -days 3650 \
  -in /etc/wazuh-indexer/certs/wazuh-indexer.csr \
  -CA /etc/wazuh-indexer/certs/root-ca.pem \
  -CAkey /etc/wazuh-indexer/certs/root-ca-key.pem \
  -CAcreateserial \
  -out /etc/wazuh-indexer/certs/wazuh-indexer.pem

# Generate admin certs (required by indexer-security-init)
openssl req -batch -nodes -newkey rsa:2048 \
  -keyout /etc/wazuh-indexer/certs/admin-key.pem \
  -out /etc/wazuh-indexer/certs/admin.csr \
  -subj "/CN=admin"
openssl x509 -req -days 3650 \
  -in /etc/wazuh-indexer/certs/admin.csr \
  -CA /etc/wazuh-indexer/certs/root-ca.pem \
  -CAkey /etc/wazuh-indexer/certs/root-ca-key.pem \
  -CAcreateserial \
  -out /etc/wazuh-indexer/certs/admin.pem

chmod 400 /etc/wazuh-indexer/certs/*
chown wazuh-indexer:wazuh-indexer /etc/wazuh-indexer/certs/*

systemctl daemon-reload
systemctl enable wazuh-indexer.service
systemctl start wazuh-indexer.service

# Initialize security settings
/usr/share/wazuh-indexer/bin/indexer-security-init.sh

## Wazuh Manager Installation
apt-get install -y wazuh-manager

# Load custom ossec.conf for Wazuh Manager
cp /var/ossec/etc/ossec.conf /var/ossec/etc/ossec.conf.bak
cat > /var/ossec/etc/ossec.conf <<'OSSEC_CONF'
${wazuh_ossec_config}
OSSEC_CONF

chown wazuh:wazuh /var/ossec/etc/ossec.conf
chmod 660 /var/ossec/etc/ossec.conf


## Wazuh Dashboard Installation
apt-get install -y wazuh-dashboard

# Configure dashboard — bind to localhost, Nginx will proxy
cat > /etc/wazuh-dashboard/opensearch_dashboards.yml <<'DASHBOARD_CONF'
server.host: 127.0.0.1
server.port: 5601
server.basePath: "/siem"
server.rewriteBasePath: true
opensearch.hosts: ["https://127.0.0.1:9200"]
opensearch.ssl.verificationMode: none
opensearch.username: "admin"
opensearch.password: "admin"
DASHBOARD_CONF

systemctl daemon-reload
systemctl enable wazuh-dashboard
systemctl start wazuh-dashboard
## End of Wazuh Installation
