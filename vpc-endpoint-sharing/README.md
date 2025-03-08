# AWS Multi-Region VPC Peering with Private Endpoints

## Overview
This Terraform project provisions AWS infrastructure to enable secure connectivity between multiple VPCs across different regions. Each VPC contains a single subnet and is connected to a central VPC (in the primary region) using VPC peering. The solution also supports AWS VPC endpoints for various AWS services, enabling private access across regions using Route 53 Private Hosted Zones.

## Features
- **Multi-Region VPC Creation:** Deploys VPCs with a single subnet in multiple AWS regions.
- **VPC Peering:** Establishes VPC peering connections between regional VPCs and a central VPC in the primary region.
- **Route Table Updates:** Modifies route tables to allow cross-region communication via VPC peering.
- **AWS VPC Endpoints:** Supports private access to AWS services (e.g., SSM, EC2) via interface endpoints.
- **Private Hosted Zones:** Creates Route 53 Private Hosted Zones for each VPC endpoint and associates them with the primary VPC.
- **DNS Resolution:** Configures Route 53 records to ensure that traffic from the primary VPC is routed to private endpoints in the corresponding regions.
- **Configurable Endpoint Creation:** The creation of VPC endpoints and private hosted zones is controlled by a `should_create` variable. When set to `true`, endpoints and private hosted zones will be created; otherwise, they will be skipped, except for the S3 gateway endpoint, which is always created as it does not incur additional costs.

## Architecture
1. **VPC Deployment:**
   - A VPC with a single subnet is created in each specified region.
   - A primary VPC is designated in one region to serve as the main network hub.
2. **VPC Peering:**
   - Each regional VPC is peered with the primary VPC.
   - Route tables are updated to allow connectivity through the peer connections.
3. **VPC Endpoints & DNS Configuration:**
   - Users specify AWS services for which VPC endpoints should be created.
   - Interface endpoints are provisioned in the regional VPCs if `should_create` is set to `true`.
   - Route 53 Private Hosted Zones are created and associated with the primary VPC only when `should_create` is `true`.
   - DNS records are added to enable private access from the primary VPC to AWS services in remote regions.
   - The S3 gateway endpoint is always created, regardless of `should_create` value.