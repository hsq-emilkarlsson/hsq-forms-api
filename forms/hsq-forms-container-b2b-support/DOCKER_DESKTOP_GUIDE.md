# 🐳 Docker Desktop Quick Start Guide

## Starta B2B Support Form från Docker Desktop

### 🎯 Snabbaste sättet:

1. **Öppna Docker Desktop**
2. **Gå till "Containers" fliken**
3. **Hitta `hsq-forms-b2b-support`**
4. **Klicka på ▶️ Start knappen**

Formuläret är nu tillgängligt på: **http://localhost:3003**

---

### 🛠 Alternativa metoder:

#### Via Terminal/Command Line:
```bash
# Navigera till projektmappen
cd /Users/emilkarlsson/Documents/Dev/hsq-forms-api/forms/hsq-forms-container-b2b-support

# Starta containern
./container.sh start

# Eller med Docker Compose direkt
docker-compose up -d
```

#### Via Container Management Script:
```bash
# Se alla tillgängliga kommandon
./container.sh

# Starta containern
./container.sh start

# Kontrollera status
./container.sh status

# Öppna i webbläsaren
./container.sh open
```

---

### 📊 Status & Monitoring

**I Docker Desktop:**
- 🟢 **Grön cirkel** = Container körs och är hälsosam
- 🟡 **Gul cirkel** = Container startar eller har problem
- 🔴 **Röd cirkel** = Container har stoppat eller fel

**Via Terminal:**
```bash
# Snabb status
./container.sh status

# Live logs
./container.sh logs-live

# Testa API integration
./container.sh test
```

---

### 🔧 Felsökning

**Container startar inte:**
1. Kontrollera att port 3003 inte används
2. Kör: `./container.sh logs`
3. Försök: `./container.sh restart`

**Formuläret laddar inte:**
1. Vänta 30-60 sekunder efter start
2. Kontrollera http://localhost:3003
3. Kontrollera health status i Docker Desktop

**API fel:**
1. Kontrollera att HSQ Forms API körs (port 8000)
2. Testa API endpoints: `./container.sh test`
3. Kontrollera nätverksanslutning

---

### 🎉 Det var allt!

Formuläret körs nu i en helt isolerad container med alla nödvändiga beroenden inkluderade. Du kan starta och stoppa det enkelt från Docker Desktop när du behöver det.

**URL**: http://localhost:3003
**Container**: `hsq-forms-b2b-support`
**Image**: `hsq-forms-container-b2b-support:latest`
