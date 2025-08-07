# 🔒 Virtual Network Integration Requirements

## Azure Policy Requirements

This document explains the necessary changes made to comply with the Azure Security Policy:
**"deny-paas-public-dev" – Container Apps requires private VNet.**

## Changes Implemented

1. **Container App Environment Configuration**:
   - Modified to always use VNet integration
   - Set as `internal: true` to comply with the security policy
   - Ensures no public endpoints are exposed

2. **Container App Ingress Configuration**:
   - Set `external: false` to prevent public access
   - Changed transport from `http` to `tcp` for secure VNet access
   - Set `allowInsecure: false` for enhanced security

3. **VNet Integration**:
   - Made `enableVNet` parameter default to `true`
   - Updated all deployment configurations to always enable VNet

## Required Permissions

The deployment pipeline service principal requires the following permissions:

```
Microsoft.Network/virtualNetworks/*
Microsoft.Network/virtualNetworks/subnets/*
```

An Azure administrator with Owner or User Access Administrator permissions needs to grant these permissions to the service principal used by the pipeline.

## How to Assign Required Permissions

1. **Identify the Service Principal**:
   - Find the service principal ID used by your Azure DevOps pipeline
   - This is typically shown in error messages or can be retrieved from Azure DevOps service connections

2. **Assign Network Contributor Role**:
   ```bash
   az role assignment create \
     --assignee "<service-principal-id>" \
     --role "Network Contributor" \
     --scope "/subscriptions/<subscription-id>/resourceGroups/<resource-group-name>"
   ```

3. **Verify Permissions**:
   ```bash
   az role assignment list \
     --assignee "<service-principal-id>" \
     --scope "/subscriptions/<subscription-id>/resourceGroups/<resource-group-name>"
   ```

## Accessing the Internal Container App

Since the Container App is now internal-only (no public endpoint), you'll need one of these methods to access it:

1. **VNet Peering**:
   - Connect your development network to the Container App's VNet
   - Requires network admin privileges

2. **Azure Application Gateway**:
   - Set up an Application Gateway in the same VNet
   - Configure it to route traffic to the Container App

3. **Private Link / Private Endpoint**:
   - Create a Private Link service for secure access
   - Connect via Private Endpoints from authorized networks

4. **Bastion Host**:
   - Deploy a VM in the same VNet as a jump box
   - Access the Container App via this VM

## Testing the Deployment

After successful deployment, verify the Container App is properly secured:

1. Attempt to access via public endpoint (should fail)
2. Access via one of the secure methods above (should succeed)
3. Verify all connections are encrypted and secure

## Support and Troubleshooting

If you encounter "AuthorizationFailed" errors:

1. Confirm the service principal has Network Contributor role
2. Check that the specific Microsoft.Network permissions are granted
3. Verify the resource group and subscription IDs match your deployment

## References

- [Azure Container Apps VNet Integration](https://learn.microsoft.com/en-us/azure/container-apps/vnet-integration)
- [Azure RBAC for Networking](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#networking)
- [Azure Security Policy Documentation](https://learn.microsoft.com/en-us/azure/governance/policy/overview)
