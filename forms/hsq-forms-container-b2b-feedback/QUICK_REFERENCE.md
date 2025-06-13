# 🚀 HSQ Forms B2B Feedback - Quick Reference

## Snabbkommandon
```bash
cd /Users/emilkarlsson/Documents/Dev/hsq-forms-api/forms/hsq-forms-container-b2b-feedback

# Vanligaste kommandon:
./dev-helper.sh quick    # Snabb rebuild efter ändringar
./dev-helper.sh dev      # Development mode
./dev-helper.sh stop     # Stoppa allt
./dev-helper.sh status   # Kontrollera status
```

## URLs
- **App:** http://localhost:3001
- **API:** http://localhost:8000

## Workflow
1. **Gör ändringar** i src/ eller andra filer
2. **Kör:** `./dev-helper.sh quick`
3. **Testa:** http://localhost:3001
4. **Upprepa** tills nöjd
5. **Deploy:** `cd ../../ && azd up`

## Troubleshooting
```bash
# Problem? Prova detta:
./dev-helper.sh clean     # Clean rebuild
docker-compose logs       # Se vad som händer
./dev-helper.sh stop      # Starta om från början
```

## Files to Edit
- **Components:** `src/components/`
- **Styles:** `src/styles/` eller `src/components/*.css`
- **Config:** `package.json`, `vite.config.js`
- **Container:** `Dockerfile`, `docker-compose.yml`
