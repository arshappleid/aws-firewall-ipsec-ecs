# All rule group resources live here.
# To manage rules, edit inspection_rules/statefull/<name>.txt then run terraform apply.

# ── Operation Protocols ───────────────────────────────────────────────────────
# Highest priority — protocol-level pass rules (WebSocket, gRPC, etc.)
# Evaluated BEFORE all other rule groups so allowed protocols are never blocked
resource "aws_networkfirewall_rule_group" "operation_protocols" {
  name        = "ALLOWED-OPERATIONAL-PROTOCOLS"
  description = "Operation protocols — pass rules for WebSocket and other allowed protocols"
  type        = "STATEFUL"
  capacity    = 50

  rule_group {
    rule_variables {
      ip_sets {
        key = "NLB"
        ip_set {
          definition = [
            "192.168.1.40/32",
            "3.147.163.252/32"
          ]
        }
      }
      ip_sets {
        key = "HOME_NET"
        ip_set {
          definition = [
            "10.0.0.0/8",
            "172.16.0.0/12",
            "192.168.0.0/16",
          ]
        }
      }
      ip_sets {
        key = "EXTERNAL_NET"
        ip_set {
          definition = ["0.0.0.0/0"]
        }
      }
    }

    rules_source {
      rules_string = join("\n", [
        for filename in sort(fileset("${path.module}/inspection_rules/statefull/ALLOWED", "*.txt")) :
        file("${path.module}/inspection_rules/statefull/ALLOWED/${filename}")
      ])
    }

    stateful_rule_options {
      rule_order = "STRICT_ORDER"
    }
  }

  tags = {
    Name        = "company-operation-protocols"
    Environment = "prod"
    Owner       = "Prabhmeet"
    Firewall    = data.aws_networkfirewall_firewall.prod_web.name
  }
}

# ── AWS Best Practices rules ─────────────────────────────────────────────────
# Suricata rules from aws_best_practices.txt with HOME_NET scoped to RFC 1918
resource "aws_networkfirewall_rule_group" "aws_best_practices" {
  name        = "aws-best-practices"
  description = "AWS best practices — Suricata rules with HOME_NET (RFC 1918)"
  type        = "STATEFUL"
  capacity    = 100

  rule_group {
    rule_variables {
      ip_sets {
        key = "HOME_NET"
        ip_set {
          definition = [
            "10.0.0.0/8",
            "172.16.0.0/12",
            "192.168.0.0/16",
          ]
        }
      }
      ip_sets {
        key = "EXTERNAL_NET"
        ip_set {
          definition = ["0.0.0.0/0"]
        }
      }

      port_sets {
        key = "HTTP_PORTS"
        port_set {
          definition = ["80", "443", "8080", "8443"]
        }
      }
      port_sets {
        key = "SSH_PORTS"
        port_set {
          definition = ["22"]
        }
      }
    }

    rules_source {
      rules_string = file("${path.module}/inspection_rules/statefull/2_aws_best_practices.txt")
    }

    stateful_rule_options {
      rule_order = "STRICT_ORDER"
    }
  }

  tags = {
    Name        = "company-aws-best-practices"
    Environment = "prod"
    Owner       = "Prabhmeet"
    Firewall    = data.aws_networkfirewall_firewall.prod_web.name
  }
}

# ── PII + Security Info Guard rules ──────────────────────────────────────────
# Consolidated Suricata rules for PII exfiltration and security information protection
resource "aws_networkfirewall_rule_group" "pii_security_info_guard" {
  name        = "pii-security-info-guard"
  description = "PII + Security info guard — consolidated Suricata rules"
  type        = "STATEFUL"
  capacity    = 200

  rule_group {
    rule_variables {
      ip_sets {
        key = "BACKEND_VPC"
        ip_set {
          definition = ["10.0.0.0/16"]
        }
      }
      ip_sets {
        key = "INSPECTION_VPC"
        ip_set {
          definition = ["192.168.1.0/26"]
        }
      }
      ip_sets {
        key = "EXTERNAL_NET"
        ip_set {
          definition = ["0.0.0.0/0"]
        }
      }

      port_sets {
        key = "ALLOW_PORTS"
        port_set {
          definition = ["22"]
        }
      }
    }

    rules_source {
      rules_string = join("\n", [
        file("${path.module}/inspection_rules/statefull/3_pii_info_guard.txt"),
        file("${path.module}/inspection_rules/statefull/4_security_info_guard.txt"),
      ])
    }

    stateful_rule_options {
      rule_order = "STRICT_ORDER"
    }
  }

  tags = {
    Name        = "company-pii-security-info-guard"
    Environment = "prod"
    Owner       = "Prabhmeet"
    Firewall    = data.aws_networkfirewall_firewall.prod_web.name
  }
}

# ── East-West Allow rules ────────────────────────────────────────────────────
# Suricata rules for east-west (inter-VPC) allowed traffic
resource "aws_networkfirewall_rule_group" "east_west_allow" {
  name        = "east-west-allow"
  description = "East-west allow — Suricata rules for inter-VPC permitted traffic"
  type        = "STATEFUL"
  capacity    = 100

  rule_group {
    rule_variables {
      ip_sets {
        key = "BACKEND_VPC"
        ip_set {
          definition = ["10.0.0.0/16"]
        }
      }
      ip_sets {
        key = "EXTERNAL_NET"
        ip_set {
          definition = ["0.0.0.0/0"]
        }
      }
      ip_sets {
        key = "INSPECTIION_VPC"
        ip_set {
          definition = ["192.168.1.0/26"]
        }
      }
      ip_sets {
        key = "PUBLIC_NLB"
        ip_set {
          definition = ["192.168.1.40/32"]
        }
      }

      port_sets {
        key = "HTTP"
        port_set {
          definition = ["80"]
        }
      }
    }

    rules_source {
      rules_string = file("${path.module}/inspection_rules/statefull/18_east_west_allow.txt")
    }

    stateful_rule_options {
      rule_order = "STRICT_ORDER"
    }
  }

  tags = {
    Name        = "company-east-west-allow"
    Environment = "prod"
    Owner       = "Prabhmeet"
    Firewall    = data.aws_networkfirewall_firewall.prod_web.name
  }
}
