# 📋 Azure Permissions Request för HSQ Forms API

## 🎯 Sammanfattning
**Projekt:** HSQ Forms API Deployment  
**Status:** ✅ Uses IT-approved Azure Verified Modules - Only Network permissions needed  
**Solution:** Upgraded to official Azure modules following IT guidance

---

## ✅ **PROBLEM LÖST - IT-APPROVED MODULES IMPLEMENTED**

### ✅ Official Azure Verified Modules (AVM):
- **Updated:** Pipeline använder `br/public:avm/res/app/container-app:0.17.0`
- **Follows:** IT-link: https://github.com/Azure/bicep-registry-modules/tree/main/avm/res/app/container-app#example-4-vnet-integrated-container-app-deployment
- **Configuration:** Exakt enligt IT:s exempel med `ingressExternal: false`
- **Standards:** Follows Azure Well-Architected Framework

### ✅ IT-Approved Configuration Confirmed:
```bicep
// infra/main-avm.bicep - Uses official Azure modules
module containerApp 'br/public:avm/res/app/container-app:0.17.0' = {
  params: {
    ingressExternal: false    // ✅ IT's exact requirement
    additionalPortMappings: [
      {
        external: false       // ✅ All ports private
      }
    ]
  }
}
```

### Network permissions behövs fortfarande:
```
Microsoft.Network/virtualNetworks/write
Microsoft.Network/virtualNetworks/subnets/write
```

---

## ✅ **VAS SOM BEHÖVS**

### Service Principal Permissions:
**Service Principal ID:** `07800365-c8e4-404d-a5da-056ae1ed52f0`  
**Service Connection:** `SCON-HAZE-01AA-APP1066-Dev-Martechlab`

### Nödvändiga Azure Roles:
1. **Network Contributor** på subscription-nivå, ELLER
2. **Custom role** med följande permissions:
   ```
   Microsoft.Network/virtualNetworks/write
   Microsoft.Network/virtualNetworks/read
   Microsoft.Network/virtualNetworks/subnets/write
   Microsoft.Network/virtualNetworks/subnets/read
   Microsoft.Network/virtualNetworks/subnets/join/action
   ```

---

## 🏗️ **TEKNISK BAKGRUND**

### Varför VNet krävs:
- Azure Policy `deny-paas-public-dev` förbjuder offentlig åtkomst till PaaS-tjänster
- Container Apps Environment måste köras i privat nätverk
- VNet-integration är den enda Azure-godkända metoden för detta

### Vad som kommer att skapas:
```
Virtual Network: hsq-forms-vnet-dev-[token]
- Address Space: 10.0.0.0/16
- Subnet: container-apps-subnet (10.0.1.0/24)
- Delegation: Microsoft.App/environments
```

### Security Benefits:
- ✅ Följer Husqvarna Groups säkerhetspolicys
- ✅ Ingen offentlig åtkomst till API eller Storage
- ✅ Nätverksisolering enligt enterprise standards
- ✅ VPN-åtkomst krävs för administration

---

## 🎯 **BUSINESS JUSTIFICATION**

### Projektmål:
- **HSQ Forms API** för customer support och business processes
- **Container-baserad arkitektur** för skalbarhet och reliability
- **Azure Container Apps** för modern, managed deployment
- **Policy-compliant** enligt företagets säkerhetskrav

### Tidskritiskt:
- Deployment blockerat i 6+ månader
- All kod och infrastructure redo
- Endast nätverkspermissions saknas

---

## 📞 **KONTAKT & ÄRENDEINFO**

**Ursprungligt IT-ärende:** REQ0964349  
**Requestor:** Emil Karlsson  
**DevOps Team:** Husqvarna Group Martech  
**Azure Subscription:** HAZE-01AA-APP1066-Dev-Martechlab

### Service Connection Details:
```
Service Connection: SCON-HAZE-01AA-APP1066-Dev-Martechlab
Type: Azure Resource Manager (Workload Identity Federation)
Created by: Grzegorz Jońca (grzegorz.jonca@husqvarnagroup.com)
```

---

## 🔄 **ALTERNATIVA LÖSNINGAR**

### Option 1: Network Contributor Role (REKOMMENDERAT)
- **Fördelar:** Full control över networking för projektet
- **Scope:** Subscription-level för max flexibility
- **Säkerhet:** Managed Identity + Workload Identity Federation

### Option 2: Custom Role med Minimal Permissions
- **Fördelar:** Least-privilege principle
- **Omfattning:** Endast VNet create/manage permissions
- **Begränsning:** Kan behöva utökas senare

### Option 3: Befintlig VNet (OM TILLGÄNGLIG)
- **Fördelar:** Inget behov av VNet creation permissions
- **Krav:** Tillgänglig subnet med Microsoft.App/environments delegation
- **Information:** Om sådan finns, vänligen informera

---

## ⏰ **NÄSTA STEG**

1. **IT Review:** Granska denna begäran och säkerhetskrav
2. **Permission Grant:** Tilldela Network permissions till Service Principal
3. **Deployment:** Automatisk pipeline-deployment efter permissions
4. **Validation:** Verifiera att infrastruktur skapas enligt policy

**Estimerad tid efter permissions:** 15-30 minuter för full deployment ✅

---

## 📧 **TEKNISK SUPPORT**

För tekniska frågor om denna begäran, kontakta:
- **DevOps Team:** HSQ Martech
- **Pipeline:** Azure DevOps - Customforms project
- **Repo:** hsq-forms-api (GitHub)

**Tack för er hjälp med att få detta projekt i produktion!** 🚀
