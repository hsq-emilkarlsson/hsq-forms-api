#!/bin/bash

# Kontrollera att ett formulärnamn har angetts
if [ -z "$1" ]; then
  echo "Ange ett namn för det nya formuläret. Exempel: ./setup_new_form.sh form-project-1"
  exit 1
fi

FORM_NAME=$1
TEMPLATE_PATH="/Users/emilkarlsson/Documents/Dev/hsq-forms-api/templates/form-app-template"
NEW_FORM_PATH="/Users/emilkarlsson/Documents/Dev/hsq-forms-api/$FORM_NAME"

# Kopiera formulärtemplatet
cp -r "$TEMPLATE_PATH" "$NEW_FORM_PATH"

# Navigera till den nya formulärmappen
cd "$NEW_FORM_PATH" || exit

# Installera beroenden
npm install

# Uppdatera API-url i formsApi.ts
sed -i '' 's|http://localhost:8000/api|https://your-backend-domain.com/api|' src/api/formsApi.ts

# Starta utvecklingsservern
npm run dev

echo "Formulärprojektet $FORM_NAME har skapats och körs nu på http://localhost:3000."
