# Guide för att sätta upp Azure DevOps Pipeline för HSQ Forms API

Detta dokument beskriver hur du sätter upp Azure DevOps-pipelinen för HSQ Forms API i utvecklingsmiljön.

## Förberedelser

Innan du kan köra pipelinen måste följande förberedelser göras:

### 1. Skapa resursgrupp

Skapa resursgruppen där alla Azure-resurser kommer att deployas:

```bash
az group create --name rg-hsq-forms-dev --location westeurope
```

### 2. Skapa Service Connection i Azure DevOps

Om du inte redan har en Service Connection för din Azure-prenumeration:

1. Gå till **Project Settings** > **Service connections** i Azure DevOps
2. Klicka på **New service connection**
3. Välj **Azure Resource Manager**
4. Välj **Service principal (automatic)**
5. Välj rätt **Subscription**
6. Ange namnet på Service Connection: `SCON-HAZE-01AA-APP1066-Dev-Martechlab`
7. Klicka på **Save**

> **OBS:** Om du vill använda ett annat namn på din Service Connection, behöver du även uppdatera namnet i pipeline-filen `azure-pipelines-dev.yml`.

### 3. Hantera databasuppgifterna

Du har två alternativ för att hantera databasuppgifterna:

#### Alternativ A: Skapa pipeline-variabler (enklast)

När du skapar pipelinen i Azure DevOps:

1. Klicka på **Variables** knappen under redigeringsläget (efter att du valt YAML-filen)
2. Lägg till variablerna en i taget:
   - Namn: `dbAdminUsername`, Värde: `hsqadmin`
   - Namn: `dbAdminPassword`, Värde: `<generera ett starkt lösenord>`, Markera som **secret**
3. Klicka på **Save**

#### Alternativ B: Skapa variable group (rekommenderat för återanvändning)

Om du planerar att återanvända dessa variabler i flera pipelines:

1. Gå till **Pipelines** > **Library** i Azure DevOps
2. Klicka på **+ Variable group**
3. Ange namn: `hsq-forms-secrets`
4. Klicka på **+ Add** för att lägga till variabler en i taget:
   - Namn: `dbAdminUsername`, Värde: `hsqadmin`
   - Namn: `dbAdminPassword`, Värde: `<generera ett starkt lösenord>`, Markera **Secret**-rutan
5. Klicka på **Save**

> **Tips för lösenord**: Använd ett starkt lösenord (minst 8 tecken, inklusive stora och små bokstäver, siffror, och specialtecken). Du kan generera ett med kommandot:
> ```bash
> openssl rand -base64 16
> ```
> Eller använd Azures lösenordsgenerator i Azure Portal

## Konfigurera pipeline

1. Gå till **Pipelines** > **Pipelines** i Azure DevOps
2. Klicka på **New pipeline**
3. Välj **Azure Repos Git** som källa
4. Välj repositoryt där koden finns
5. Välj **Existing Azure Pipelines YAML file**
6. Välj `azure-pipelines-dev.yml` från listan
7. Klicka på **Continue**
8. **Om du valde Alternativ A (pipeline-variabler)**: 
   - Klicka på **Variables** knappen
   - Lägg till variablerna som beskrivs ovan
9. Granska pipeline-konfigurationen
10. Klicka på **Run**

## Resurserna som skapas

När pipelinen körs skapas följande resurser i Azure:

| Resurstyp | Namnmönster | Beskrivning |
|-----------|-------------|-------------|
| Virtual Network | `hsq-forms-vnet-dev-[token]` | VNet med tre subnät |
| App Service Plan | `hsq-forms-plan-dev-[token]` | B1 App Service Plan |
| App Service | `hsq-forms-api-dev-[token]` | Python 3.11 web app med VNet-integration |
| PostgreSQL Flexible Server | `hsq-forms-dev-[token]` | Standard_B1ms med VNet-integration |
| PostgreSQL Database | `hsq_forms` | Databas på PostgreSQL-servern |
| Storage Account | `hsqformsdev[token]` | För att lagra formulärbilagor med Private Endpoint |
| Private DNS Zones | - | För PostgreSQL och Storage |
| Private Endpoints | - | För säker kommunikation inom VNet |
| Log Analytics Workspace | `hsq-forms-logs-dev-[token]` | För loggning |
| Application Insights | `hsq-forms-insights-dev-[token]` | För övervakning |
| Managed Identity | `hsq-forms-identity-dev-[token]` | För autentisering |

Där `[token]` är en unik identifierare som genereras baserat på din prenumeration, resursgrupp och miljö.

> **OBS:** På grund av företagets Azure Policy-krav (`deny-paas-public-dev`) konfigureras alla resurser med privat nätverksåtkomst. Detta innebär att resurserna endast är tillgängliga från inom det VNet som skapas.

## Verifiera deployment

När pipelinen har körts klart kan du verifiera att allt fungerar korrekt:

1. Gå till Azure Portal och öppna resursgruppen `rg-hsq-forms-dev`
2. Kontrollera att alla resurser har skapats korrekt, särskilt VNet, Private Endpoints och App Service

> **OBS:** På grund av privat nätverksåtkomst kommer du inte att kunna öppna applikationen direkt från internet. För att testa applikationen behöver du:
>
> 1. Skapa en Jump Host (VM) i samma VNet
> 2. Konfigurera VPN-åtkomst till VNet-et
> 3. Använd Azure Bastion för att ansluta till en VM i samma VNet

Du kan verifiera deployment status med testskriptet (om det körs från en maskin med VNet-åtkomst):

```bash
./scripts/test-appservice-deployment.sh rg-hsq-forms-dev hsq-forms-api-dev-[token] dev
```

## Databasuppgifter och credentials

Dina angivna databas-credentials används för:

1. **Admin-åtkomst till PostgreSQL**: Användarnamnet och lösenordet används för att skapa databasen och hantera PostgreSQL-servern.

2. **Applikationens databas-connection**: De genereras automatiskt i applikationens connection string:
   ```
   SQLALCHEMY_DATABASE_URI=postgresql://hsqadmin:<ditt-lösenord>@<db-server-namn>.postgres.database.azure.com:5432/hsq_forms
   ```

3. **Lagring**: Credentials lagras säkert i Azure Key Vault och är endast tillgängliga för App Service och pipeline via Managed Identity.

> **OBS:** För ytterligare säkerhet bör du överväga att skapa en separat databasanvändare med begränsade rättigheter för applikationen efter den initiala deploymentet.

## Felsökning

Om du stöter på problem under deployment:

1. **Policy-relaterade problem**:
   - Felmeddelanden om "PolicyViolation" indikerar konflikter med företagets Azure Policies
   - Vi använder en VNet-integrerad mall i `main-appservice.bicep` för att hantera policy-kraven
   - Om du fortfarande får policy-fel, kontakta din Azure-administratör för undantag

2. **VNet-relaterade problem**:
   - Kontrollera att resurserna har korrekt VNet-konfiguration
   - Verifiera att Private Endpoints är korrekt uppsatta
   - DNS-upplösning kan behöva konfigureras korrekt

3. **Allmän felsökning**:
   - Kontrollera pipeline-loggar i Azure DevOps
   - Kontrollera resursloggarna i Azure Portal
   - Verifiera att alla miljövariabler är korrekt konfigurerade
   - Kontrollera att Service Connection har rätt behörigheter

> **OBS:** Deployment med VNet-integration tar längre tid (15-20 minuter) jämfört med standard-deployment.

## Nästa steg

När utvecklingsmiljön fungerar korrekt kan du konfigurera produktionsmiljön på liknande sätt, men använd då `azure-pipelines-prod.yml`.
