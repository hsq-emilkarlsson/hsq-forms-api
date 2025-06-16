# Admin Support Request - HSQ Forms Azure Deployment

**Till:** Azure Admin Team / Infrastructure Team  
**Från:** Emil Karlsson <emil.karlsson@husqvarnagroup.com>  
**Ärende:** Azure Container Registry Access för HSQ Forms Production Deployment  
**Prioritet:** Hög  

---

Hej Azure Admin Team,

Jag behöver er hjälp för att slutföra deployment av HSQ Forms API till Azure Container Apps. Projektet är i slutfasen (90% klart) men blockeras av en behörighetsfråga som kräver admin-rättigheter.

## 🎯 Vad jag behöver

**En role assignment för Container App Managed Identity att kunna hämta images från Azure Container Registry.**

### Specifikt kommando som behöver köras:
```bash
az role assignment create \
  --assignee 8f46f002-4cc2-4278-b4ff-f10ade449495 \
  --role "AcrPull" \
  --scope "/subscriptions/c0b03b12-570f-4442-b337-c9175ad4037f/resourceGroups/rg-hsq-forms-prod-westeu/providers/Microsoft.ContainerRegistry/registries/hsqformsprodacr"
```

## 📋 Teknisk Context

### Resurser som påverkas:
- **Subscription:** c0b03b12-570f-4442-b337-c9175ad4037f
- **Resource Group:** rg-hsq-forms-prod-westeu  
- **Container App:** hsq-forms-api-v2
- **Container Registry:** hsqformsprodacr.azurecr.io
- **Managed Identity Principal ID:** 8f46f002-4cc2-4278-b4ff-f10ade449495

### Nuvarande status:
✅ Container App är skapad och fungerande  
✅ Alla container images är byggda och pushade till ACR  
✅ Managed Identity är aktiverad  
✅ Infrastrukturen följer alla company policies  
❌ **Blockerad:** Container App kan inte hämta images från ACR

## 🚫 Problem Description

**Error:** Container App får authentication failure när den försöker hämta images från Container Registry.

**Root Cause:** Managed Identity saknar AcrPull-behörighet på Container Registry.

**Why Admin Needed:** Jag har inte behörighet att tilldela roller på subscription/resource group-nivå.

## 🔐 Security & Compliance

Detta är den **rekommenderade säkra metoden** enligt Azure best practices:
- ✅ Använder Managed Identity (inga hardcoded credentials)  
- ✅ Least privilege (endast AcrPull, inte admin)  
- ✅ Följer company policies (kan inte använda ACR admin user)  
- ✅ Production-ready security approach  

## ⏱️ Business Impact

**Timeline:** Detta är det sista steget för att få HSQ Forms live i production.

**Current State:** Allt är förberett och väntar endast på denna behörighet.

**Next Steps Efter Admin Action:**
1. Deploy HSQ Forms API till Container App
2. Deploy formulären (B2B Support, Returns, Feedback)
3. Konfigurera production environment variables
4. Go-live för användare

## 📞 Contact & Follow-up

**Emil Karlsson**  
emil.karlsson@husqvarnagroup.com  
Teams: @emil.karlsson  

Jag är tillgänglig för questions eller om ni behöver ytterligare information.

**Tack så mycket för er hjälp!** 🙏

---

*Med vänliga hälsningar,*  
*Emil Karlsson*  
*Developer - HSQ Forms Project*  
*Husqvarna Group*
