data "aws_region" "current" {}

locals {
  # AWS managed stateful rule groups enabled in console, codified in Terraform.
  aws_managed_stateful_rule_groups = {
    25 = "arn:aws:network-firewall:${data.aws_region.current.name}:aws-managed:stateful-rulegroup/AbusedLegitMalwareDomainsStrictOrder"
    26 = "arn:aws:network-firewall:${data.aws_region.current.name}:aws-managed:stateful-rulegroup/BotNetCommandAndControlDomainsStrictOrder"
    27 = "arn:aws:network-firewall:${data.aws_region.current.name}:aws-managed:stateful-rulegroup/AbusedLegitBotNetCommandAndControlDomainsStrictOrder"
    28 = "arn:aws:network-firewall:${data.aws_region.current.name}:aws-managed:stateful-rulegroup/MalwareDomainsStrictOrder"
    29 = "arn:aws:network-firewall:${data.aws_region.current.name}:aws-managed:stateful-rulegroup/ThreatSignaturesIOCStrictOrder"
    30 = "arn:aws:network-firewall:${data.aws_region.current.name}:aws-managed:stateful-rulegroup/ThreatSignaturesPhishingStrictOrder"
  }
}
