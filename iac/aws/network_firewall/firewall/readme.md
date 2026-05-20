## AWS Managed Rule Groups (Console-managed)

These are **not** managed by Terraform. Toggle on/off in the AWS Console:  
**Console → VPC → Network Firewall → Firewall policies → Company-Custom-Firewall**

| Priority | Name | Capacity | Managed | Description |
|----------|------|----------|---------|-------------|
| 11 | `AbusedLegitMalwareDomainsStrictOrder` | 200 | Yes | Domains on legitimate services abused for malware distribution |
| 12 | `BotNetCommandAndControlDomainsStrictOrder` | 200 | Yes | Known botnet command & control domains |
| 13 | `AbusedLegitBotNetCommandAndControlDomainsStrictOrder` | 200 | Yes | Legitimate domains abused for botnet C2 |
| 14 | `MalwareDomainsStrictOrder` | 200 | Yes | Known malware hosting domains |
| 15 | `ThreatSignaturesBotnetWebStrictOrder` | 3500 | Yes | Botnet web traffic signatures |
| 16 | `ThreatSignaturesDosStrictOrder` | 200 | Yes | Denial of service attack signatures |

