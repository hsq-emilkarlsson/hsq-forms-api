# 🔍 ALTERNATIVA DEPLOYMENT-STRATEGIER

## ❌ **FELAKTIG ANTAGANDE I NUVARANDE APPROACH**
Vi har antagit att VNet **MÅSTE** skapas för att uppfylla Azure Policy.

## ✅ **MICROSOFT DOKUMENTATION VISAR ALTERNATIV:**

### 1. **Container Apps Environment UTAN Custom VNet**
```
Azure Container Apps Environment kan skapas i TWO modes:
1. DEFAULT Azure Network (no custom VNet required) 
2. Custom VNet (requires network permissions)

POLICY CHECK: "ingressExternal: false" fungerar i BÅDA fallen!
```

### 2. **Azure Policy Requirements:**
- **Requirement:** "No public endpoints" 
- **Solution 1:** Custom VNet + Internal = ✅
- **Solution 2:** Default Network + Internal Ingress = ✅ (??)

## 🧪 **TEST STRATEGIES:**

### Strategy 1: Default Network + Internal Ingress
```bicep
// NO VNet creation - uses Azure's default network
resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2023-05-01' = {
  properties: {
    // NO vnetConfiguration - uses default Azure network
    appLogsConfiguration: { ... }
  }
}

resource containerApp 'Microsoft.App/containerApps@2023-05-01' = {
  properties: {
    configuration: {
      ingress: {
        external: false  // Still private!
        // Routes to VNet-scope only, no public internet
      }
    }
  }
}
```

### Strategy 2: Use Existing VNet (IT Option 3)
```
IF Husqvarna Group has existing VNets with Container Apps delegation:
- Use existing VNet resource ID
- No need to CREATE new VNet
- Only requires JOIN permissions (not WRITE)
```

### Strategy 3: Consumption-Only Environment (Smaller Subnet)
```
Current: Workload Profiles (/27 subnet minimum)
Alternative: Consumption-Only (/23 subnet minimum)
May have different policy implications
```

## 🎯 **IMMEDIATE ACTIONS:**

1. Test Strategy 1: Remove VNet from template entirely
2. Contact IT: Ask about existing VNets with delegation
3. Test minimal template that doesn't create VNet

## 📋 **QUESTIONS FOR IT:**
1. Does policy require Custom VNet or just Internal Ingress?
2. Are there existing VNets with Microsoft.App/environments delegation?
3. Would "default Azure network + internal ingress" satisfy policy?
