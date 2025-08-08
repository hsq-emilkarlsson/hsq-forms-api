# 🚀 Azure DevOps Pipelines - HSQ Forms API

Det här dokumentet beskriver de olika pipeline-filerna som finns i projektet och hur de används.

## 📋 Pipeline-filer

### 1. `azure-pipelines-infra.yml` - Infrastruktur testning (REKOMMENDERAD)
**Användning:** Används för att testa och deployera de olika Bicep-approacherna via Azure DevOps.

**Funktioner:**
- Dropdown-meny för att välja vilken approach som ska testas
- Validering och förhandsgranskning av infrastruktur
- Deployment av vald approach
- Visa information om deployade resurser
- Möjlighet att validera utan att deploya

**Fördelar:**
- Enkel att använda via Azure DevOps interface
- Stödjer alla infrastruktur-approacher
- Tydlig output och feedback
- Designad specifikt för infrastruktur-testning

### 2. `azure-pipelines.yml` - Komplett pipeline
**Användning:** Den primära pipeline-filen för CI/CD i produktion.

**Funktioner:**
- Kör tester
- Bygger och publicerar Docker-images
- Deployar infrastruktur
- Deployar applikationen till DEV och PROD miljöer

**Fördelar:**
- Hanterar hela CI/CD-processen från test till produktion
- Stödjer både DEV och PROD miljöer

### 3. `azure-pipelines-simple.yml` - Förenklad pipeline
**Användning:** En förenklad version för snabb deployment.

**Funktioner:**
- Kör tester
- Visar manuella instruktioner för deployment
- Enklare konfiguration

**Fördelar:**
- Minimala förutsättningar
- Bra för att komma igång snabbt

### 4. `azure-pipelines-updated.yml` - Uppdaterad pipeline
**Användning:** En uppdaterad version av huvudpipelinen med förbättringar.

**Funktioner:**
- Samma grundfunktioner som huvudpipelinen
- Förbättrad miljöhantering

## 🎯 Rekommendationer

1. För att **testa infrastruktur-approacher**: Använd `azure-pipelines-infra.yml`
2. För **CI/CD i produktion**: Använd `azure-pipelines.yml`
3. För **snabb deployment utan full CI/CD**: Använd `azure-pipelines-simple.yml`

## 📋 Så använder du infrastructure-testning pipline

1. I Azure DevOps, navigera till Pipelines
2. Välj "New pipeline" eller gå till den befintliga "HSQ Forms API - Infra Testing"
3. Om du skapar en ny:
   - Välj "Azure Repos Git" som källa
   - Välj ditt repository
   - Välj "Existing Azure Pipelines YAML file"
   - Välj `/azure-pipelines-infra.yml`
4. Klicka på "Run"
5. Välj approach att testa från dropdown-menyn
6. Klicka på "Run" igen

Pipelinen kommer nu att:
1. Validera Bicep-mallen
2. Visa en förhandsgranskning av ändringarna
3. Deploya infrastrukturen (om du valt att göra det)
4. Visa information om de deployade resurserna

## 🔄 Jämförelse med Bash-skript

Om du föredrar att testa direkt från terminalen utan Azure DevOps, kan du använda det medföljande `deploy-infra.sh`-skriptet:

```bash
# Testa "minimal" approach i utvecklingsmiljön
./deploy-infra.sh 02-minimal dev

# Testa "no-vnet" approach i produktionsmiljön
./deploy-infra.sh 03-no-vnet prod
```

Skriptet ger samma funktionalitet som pipline, men kan köras lokalt eller i en container.

## 🛠️ Pipeline-rensning

När projektet är redo för produktion bör du:

1. Behålla `azure-pipelines.yml` som din huvudpipeline
2. Behålla `azure-pipelines-infra.yml` för infrastruktur-testning
3. Överväga att ta bort de övriga pipeline-filerna för att undvika förvirring
