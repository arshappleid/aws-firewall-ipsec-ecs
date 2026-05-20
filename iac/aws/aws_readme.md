## Ingress Traffic
Client → CloudFront → WAF → API Gateway → ALB → ECS (Backend VPC)
## Egress Traffic
ECS → TGW → Inspection VPC → NFW → Egress VPC → NAT GW → Internet