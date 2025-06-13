# 🚀 HSQ Forms B2B Returns - Quick Reference

## Snabbkommandon
```bash
cd /Users/emilkarlsson/Documents/Dev/hsq-forms-api/forms/hsq-forms-container-b2b-returns

# Vanligaste kommandon:
./dev-helper.sh quick    # Snabb rebuild efter ändringar
./dev-helper.sh dev      # Development mode
./dev-helper.sh stop     # Stoppa allt
./dev-helper.sh status   # Kontrollera status
```

## URLs
- **App:** http://localhost:3002
- **API:** http://localhost:8000

## Workflow
1. **Gör ändringar** i src/ eller andra filer
2. **Kör:** `./dev-helper.sh quick`
3. **Testa:** http://localhost:3002
4. **Testa språkväxling:** EN/SE/DE
5. **Upprepa** tills nöjd
6. **Deploy:** `cd ../../ && azd up`

## Troubleshooting
```bash
# Problem? Prova detta:
./dev-helper.sh clean     # Clean rebuild
docker-compose logs       # Se vad som händer
./dev-helper.sh stop      # Starta om från början
```

## Files to Edit
- **Main Form:** `src/components/B2BReturnsForm.tsx`
- **Languages:** `src/i18n.js`
- **Styles:** `src/index.css` (Tailwind)
- **Config:** `package.json`, `vite.config.ts`, `tsconfig.json`
- **Container:** `Dockerfile`, `docker-compose.yml`

## Form Testing Checklist
- [ ] Alla obligatoriska fält fungerar
- [ ] Språkväxling (EN/SE/DE) fungerar
- [ ] Formulär skickar till API (http://localhost:8000)
- [ ] Validering visar korrekta felmeddelanden
- [ ] Responsiv design fungerar på mobil
