Egress Only Inspection. 


## Reference
1. [AWS Blog](https://aws.amazon.com/blogs/networking-and-content-delivery/deploy-centralized-traffic-filtering-using-aws-network-firewall/)

## How to Add new Connection
Suppose You want to Add Workload-VPC-1. 
1. Create a VPC Attachment for Workload-VPC-1. 
2. Create a Route in the Firewall Route Table Table for Workload-VPC-1. 
3. In Workload-VPC-1 route table, replace the default route in Private Subnet to the TGW Attachment ID. 