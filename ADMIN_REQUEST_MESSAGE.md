# HSQ Forms API - Admin Intervention Request

**Datum:** 15 juni 2025  
**Från:** Emil Karlsson  
**Ärende:** Container Registry Access för HSQ Forms Deployment  

## 🎯 Vad jag behöver hjälp med

Jag behöver **admin-behörigheter** för att slutföra deployment av HSQ Forms API till Azure Container Apps. Specifikt behöver jag:

### ✅ Container App Managed Identity tilldelning av AcrPull-roll

**Kommando som behöver köras:**
```bash
az role assignment create \
  --assignee 8f46f002-4cc2-4278-b4ff-f10ade449495 \
  --role "AcrPull" \
  --scope "/subscriptions/c0b03b12-570f-4442-b337-c9175ad4037f/resourceGroups/rg-hsq-forms-prod-westeu/providers/Microsoft.ContainerRegistry/registries/hsqformsprodacr"
```

## 📋 Teknisk Information

### Resurser som påverkas:
- **Container App:** `hsq-forms-api-v2` (redan skapad)
- **Managed Identity Principal ID:** `8f46f002-4cc2-4278-b4ff-f10ade449495`
- **Container Registry:** `hsqformsprodacr.azurecr.io`
- **Resource Group:** `rg-hsq-forms-prod-westeu`

### Vad som redan fungerar:
- ✅ Container App är skapad och körs (med placeholder nginx)
- ✅ Alla container images är byggda och pushade till ACR
- ✅ Managed Identity är aktiverad
- ✅ All infrastruktur följer company policies (internal ingress, etc.)

## 🚫 Nuvarande Problem

**Felet:** Container App kan inte hämta images från ACR på grund av saknade behörigheter.

**Error message:**
```
No credential was provided to access Azure Container Registry. 
Trying to look up credentials...
Failed to retrieve credentials for container registry hsqformsprodacr
```

## 🔧 Varför behövs detta?

1. **Security Best Practice:** Använder Managed Identity istället för admin credentials
2. **Policy Compliance:** Kan inte aktivera ACR admin user på grund av company policies  
3. **Production Ready:** Detta är den rekommenderade säkra metoden för Container Apps

## ⏱️ Tidsram

**Kritiskt:** Deployment är 90% klar och väntar endast på denna behörighet för att slutföras.

**Påverkan:** Utan detta kan jag inte uppdatera Container App med de faktiska application images.

## 🎯 Nästa Steg efter Admin-åtgärd

När behörigheten är tilldelad kommer jag att:
1. Uppdatera main Container App med HSQ Forms API image
2. Skapa Container Apps för alla formulär (B2B/B2C)
3. Konfigurera environment variables och networking
4. Slutföra produktionsdeploy

## 📞 Kontakt

Emil Karlsson  
emil.karlsson@husqvarnagroup.com

**Tack på förhand för hjälpen!** 🙏
