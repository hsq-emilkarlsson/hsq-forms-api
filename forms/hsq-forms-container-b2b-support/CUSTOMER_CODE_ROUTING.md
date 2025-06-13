# Customer Code Routing - Husqvarna Group API Integration

## Bakgrund från kollega (10 juni 2025)

Din kollega har bekräftat att:
- **Account API är implementerat** ✅
- **API-nyckel skickas separat** (på Teams) 🔑
- **Alla frågor går till EMEA för tillfället** (customerCode: DOJ)
- **APAC routing behövs senare** - väntar på lista med customerCodes

## Nuvarande Implementation

### Customer Code Mapping
```typescript
// Nuvarande standardvärde för alla kunder
const customerCode = 'DOJ'; // EMEA routing
```

### API Endpoint (Verifierat)
```
https://api-qa.integration.husqvarnagroup.com/hqw170/v1/accounts?customerNumber=1411768&customerCode=DOJ
```

### Test Customer Number
- **Riktig kunddata**: `1411768` (från kollega)
- **Customer Code**: `DOJ` (EMEA)

## Framtida APAC Routing Implementation

När listan över APAC customerCodes är tillgänglig, implementera routing-logik:

```typescript
// Framtida implementation för regional routing
const getCustomerCodeByRegion = (customerNumber: string): string => {
  // Lista från kollega (väntar på information)
  const apacCustomerCodes = [
    // TODO: Lägg till APAC codes när de är tillgängliga
    // 'APJ', 'ASIA', 'PACIFIC', etc.
  ];
  
  // För nu: alla till EMEA
  return 'DOJ';
  
  // Framtida logik:
  // if (apacCustomerCodes.includes(someLogic(customerNumber))) {
  //   return 'APAC_CODE'; // Specifik kod för APAC
  // }
  // return 'DOJ'; // Default EMEA
};
```

## Test Scenarios

### 1. EMEA Customer (Nuvarande)
```bash
Customer Number: 1411768
Customer Code: DOJ
Region: EMEA
Expected: Success med riktig kunddata
```

### 2. APAC Customer (Framtida)
```bash
Customer Number: [TBD från kollega]
Customer Code: [TBD från kollega]
Region: APAC
Expected: Success med APAC routing
```

## Action Items

### ✅ Genomfört
- [x] Account API endpoint implementerat
- [x] DOJ (EMEA) routing implementerat
- [x] Test med riktig kunddata (1411768)

### ⏳ Väntar på
- [ ] **API-nyckel från kollega** (Teams meddelande)
- [ ] **Lista på APAC customerCodes** för routing-logik
- [ ] **APAC test kundnummer** för verifiering

### 🔄 Nästa steg när informationen kommer
1. **Uppdatera API-nyckel** i miljövariabler
2. **Implementera APAC routing** baserat på customerCode-lista
3. **Testa båda regionerna** (EMEA + APAC)
4. **Uppdatera dokumentation** med komplett routing-tabell

## Kod som behöver uppdateras för APAC

### 1. Customer Validation Function
```typescript
// I B2BSupportForm.tsx, uppdatera:
const customerCode = getCustomerCodeByRegion(customerNum);
```

### 2. Case Submission
```typescript
// I formulär submission, uppdatera:
const customerCode = getCustomerCodeByRegion(data.customerNumber);
```

### 3. Environment Variables
```env
# Lägg till när APAC endpoint är känt
VITE_HUSQVARNA_API_APAC_BASE_URL=[TBD]
```

## Kommunikation med kollega

**Nästa meddelande att skicka:**
```
Hej!

Tack för informationen om Account API! 

Implementerat och testat med:
- kundnummer: 1411768
- customerCode: DOJ (EMEA)
- endpoint: api-qa.integration.husqvarnagroup.com/hqw170/v1/accounts

Frågor:
1. Hur får jag API-nyckeln du nämnde? (Teams)
2. Har du listan på customerCodes för APAC routing än?
3. Finns det test-kundnummer för APAC också?

Koden är klar att hantera båda regionerna när informationen finns!

/Emil
```
