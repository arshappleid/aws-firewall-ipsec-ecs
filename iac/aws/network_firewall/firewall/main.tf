# ── Firewall policy for prod-web-firewall-us-east-2 ──────────────────────────
# Attaches rule groups to the existing firewall's policy
resource "aws_networkfirewall_firewall_policy" "prod_web" {
  name        = "Company-Custom-Firewall"
  description = "Firewall policy for prod-web-firewall-us-east-2 — AWS best practices rules"

  firewall_policy {
    # Forward all traffic to the stateful engine — Suricata handles all decisions
    stateless_default_actions          = ["aws:forward_to_sfe"]
    stateless_fragment_default_actions = ["aws:forward_to_sfe"]

    stateful_engine_options {
      rule_order = "STRICT_ORDER"
    }



    stateful_rule_group_reference {
      priority     = 2
      resource_arn = aws_networkfirewall_rule_group.aws_best_practices.arn
    }

    stateful_rule_group_reference {
      priority     = 3
      resource_arn = aws_networkfirewall_rule_group.pii_security_info_guard.arn
    }

    # AWS Managed rule groups (priorities 25–30) are defined in managed_stateful_rule_groups.tf
    dynamic "stateful_rule_group_reference" {
      for_each = local.aws_managed_stateful_rule_groups
      content {
        priority     = tonumber(stateful_rule_group_reference.key)
        resource_arn = stateful_rule_group_reference.value
      }
    }

    # Last Priority - Allow Control North-South or EAST West Traffic
    stateful_rule_group_reference {
      priority     = 18
      resource_arn = aws_networkfirewall_rule_group.east_west_allow.arn
    }

    stateful_rule_group_reference {
      priority     = 31
      resource_arn = aws_networkfirewall_rule_group.operation_protocols.arn
    }

  }

  tags = {
    Name        = "prod-web-firewall-policy"
    Environment = "prod"
    Owner       = "Prabhmeet"
  }

  # TEMPORARILY COMMENTED OUT — uncomment after `terraform apply` pushes the new rule group references
  # Ignore AWS Managed rule groups added/removed via Console
  # lifecycle {
  #   ignore_changes = [
  #     firewall_policy[0].stateful_rule_group_reference,
  #   ]
  # }
}

