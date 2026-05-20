# ── Existing firewall lookup ──────────────────────────────────────────────────
# Imports the already-created prod web firewall by name
data "aws_networkfirewall_firewall" "prod_web" {
  name = "prod-web-firewall-us-east-2"
}

