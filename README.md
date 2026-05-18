**Author** : Prabhmeet Deol

# AWS Network Security Architecture with Centralized Firewall Inspection

This repo shows how to implement complete network security through AWS Cloud Services. It primarily relies on the following services. 

1. Cloudfront CDN - Restricts Access to Specific Countries.
2. AWS WAF - Layer 7 Firewall allowing blocking of traffic based on malicious signatures, malicious IPs, routes, and JA4 signature.
3. AWS Network Firewall - Security through Suricata rules across layers 3-7. AWS Network Firewall also offers Deep Packet Inspection, allowing you to write rules based on specific information leaving or entering the network. 

## Future Consideration

4. AWS DNS Firewall - If the solution changes to an enterprise solution where employees use the internal AWS network to access the internet. DNS firewall can inspect DNS resolution calls and reject DNS resolution requests based on entropy of DNS requests. This becomes useful in enterprise networks where employees access different websites, and it becomes difficult to whitelist specific IPs. 

# Architecture Description
![Centralized Firewall Inspection Model](/assets/images/architecture_design.png)
This environment uses the central firewall inspection model of AWS. CloudFront and AWS WAF offer layer 7 traffic inspection and prevention against botnets and DDoS attacks. Network Firewall primarily offers deep packet inspection, allowing you to write rules for egress inspection of PII, HIPAA, or SOC-compliance-related data.

This architecture has two Egress Endpoints (NAT, Central NLB) and one ingress endpoint (Central NLB). Therefore reducing the cost, and security threat scope to the bare minimum. 

Security groups should be used to limit ingress traffic to the Central NLB only from Cloudfront Prefix-lists, and to control TCP/UDP traffic at layer 4. This way all API requests can be routed through the Private Network, without having to travel the public internet. Although this adds cost for Managing a VPN 

### IPSec Connectivity to Azure Networks
If the Azure Network Only has Layer 7 workloads, AWS WAF is sufficient to secure it. For Advanced Threat Detection (Implementing DDoS alerts for PII), a site-to-site 

## Security Consideration
CloudFront terminates TLS for the actual domain owned but re-encrypts traffic to offer encryption of data in transit to the private network/central load balancer. 

Central load balancer terminates TLS and forwards only TCP traffic to targets. This allows the network firewall to inspect unencrypted traffic. 

## Scalability Consideration
AWS ECS and Fargate solutions easily add more compute units as traffic scales. Costs can be reduced by utilizing spot instances paired with automation to switch to on-demand instances to benefit from varied pricing. 

## Different Architecture Considerations
Placing the network firewall before the NLB preserves the source IP of the packet and allows you to write Suricata rules based on it. Although in the current architecture, that would be redundant since traffic is primarily forwarded by CloudFront, so all source IPs will be from the CloudFront edge location. 

## Cost Considerations
Network Firewall logs and WAF logs can be stored in an S3 bucket and then queried using Athena. Otherwise, the frequency of logs could increase costs significantly. 

## Network Connectivity Considerations
AWS Transit Gateway acts as a layer 3 router that allows you to connect different application network workloads. Access to different VPCs can be controlled through route tables attached to each VPC attachment.

Limit the use of TGW attachments due to monthly costs and the free availability of VPC peer connections for workloads that do not require hub and spoke connectivity. VPC peer connections are also free, just not transitive.

VPC Private Link can be used to secure private API workloads for east-west HTTP traffic without having to publicly expose APIs. 

## Analyzing traffic
Athena can help query and analyze logs to identify which specific rule is blocking which traffic. This can be used to carefully write Suricata rules for layers 3-7 to control which traffic is allowed.

### SIEM Solution
The following SIEM solutions can be implemented depending on different cost considerations. All solutions provide advanced levels of security through their ML threat detection system. Different organizations choose a solution based on different levels of threat to their data. 

All solutions integrate with MITRE ATT&CK defense frameworks to identify various attacks.

1. Splunk - $170/month - Best-in-class search and analytics capabilities.
2. Datadog - $15-50/month per host - Unified monitoring across infrastructure and applications.
3. Wazuh - Free, Open Source - Community-driven threat detection with no licensing costs.

# References
1. [AWS Network Firewall Best Practices](https://aws.github.io/aws-security-services-best-practices/guides/network-firewall/)
2. [AWS WAF Best Practices](https://aws.github.io/aws-security-services-best-practices/guides/waf/)
3. [AWS DNS Firewall Best Practices](https://aws.github.io/aws-security-services-best-practices/guides/dns-firewall/)

