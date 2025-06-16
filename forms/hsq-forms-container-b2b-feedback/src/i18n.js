import i18n from 'i18next';
import { initReactI18next } from 'react-i18next';

const resources = {
  en: {
    translation: {
      app: {
        subtitle: 'B2B Feedback Portal',
        footer: 'All rights reserved.',
      },
      feedback: {
        title: 'Feedback Form',
        description: 'Thank you for helping us improve the portal!',
        usage: 'We collect ideas and suggestions to make the portal better and easier to use.',
        note: 'Please note: If you have a technical problem (e.g., cannot log in, cannot place an order), please contact customer service so we can help you directly.',
        message: 'Your feedback',
        messagePlaceholder: 'Share your ideas, suggestions and feedback to make the portal better...',
        attachments: 'Attachments',
        optional: 'Optional',
        uploadFile: 'Upload file',
        dragDrop: 'or drag and drop',
        fileTypes: 'PNG, JPG, PDF, DOC up to 10MB',
        submit: 'Submit feedback',
        submitting: 'Submitting...',
      },
      form: {
        success: 'Form submitted successfully!',
        error: 'Failed to submit form. Please try again.',
      },
    },
  },
  sv: {
    translation: {
      app: {
        subtitle: 'B2B Återkopplingsportal',
        footer: 'Alla rättigheter förbehållna.',
      },
      feedback: {
        title: 'Feedback Form',
        description: 'Tack för att du hjälper oss att förbättra portalen!',
        usage: 'Vi samlar in idéer och förslag för att göra portalen bättre och enklare att använda.',
        note: 'Observera: Om du har ett tekniskt problem (t.ex. kan inte logga in, kan inte lägga en beställning), vänligen kontakta kundtjänst så att vi kan hjälpa dig direkt.',
        message: 'Din feedback',
        messagePlaceholder: 'Dela med dig av dina idéer, förslag och synpunkter för att göra portalen bättre...',
        attachments: 'Bifogade filer',
        optional: 'Valfritt',
        uploadFile: 'Ladda upp fil',
        dragDrop: 'eller dra och släpp',
        fileTypes: 'PNG, JPG, PDF, DOC upp till 10MB',
        submit: 'Skicka feedback',
        submitting: 'Skickar...',
      },
      form: {
        success: 'Formuläret skickades framgångsrikt!',
        error: 'Misslyckades att skicka formuläret. Försök igen.',
      },
    },
  },
  de: {
    translation: {
      app: {
        subtitle: 'B2B Feedback-Portal',
        footer: 'Alle Rechte vorbehalten.',
      },
      feedback: {
        title: 'Feedback Form',
        description: 'Vielen Dank, dass Sie uns bei der Verbesserung des Portals helfen!',
        usage: 'Wir sammeln Ideen und Vorschläge, um das Portal besser und einfacher zu bedienen.',
        note: 'Bitte beachten Sie: Wenn Sie ein technisches Problem haben (z.B. können sich nicht anmelden, können keine Bestellung aufgeben), wenden Sie sich bitte an den Kundendienst, damit wir Ihnen direkt helfen können.',
        message: 'Ihr Feedback',
        messagePlaceholder: 'Teilen Sie Ihre Ideen, Vorschläge und Feedback mit, um das Portal zu verbessern...',
        attachments: 'Anhänge',
        optional: 'Optional',
        uploadFile: 'Datei hochladen',
        dragDrop: 'oder ziehen und ablegen',
        fileTypes: 'PNG, JPG, PDF, DOC bis zu 10MB',
        submit: 'Feedback senden',
        submitting: 'Wird gesendet...',
      },
      form: {
        success: 'Formular erfolgreich gesendet!',
        error: 'Fehler beim Senden des Formulars. Bitte versuchen Sie es erneut.',
      },
    },
  },
  da: {
    translation: {
      app: {
        subtitle: 'B2B Feedback Portal',
        footer: 'Alle rettigheder forbeholdes.',
      },
      feedback: {
        title: 'Feedback Form',
        description: 'Tak fordi du hjælper os med at forbedre portalen!',
        usage: 'Vi indsamler idéer og forslag for at gøre portalen bedre og nemmere at bruge.',
        note: 'Bemærk: Hvis du har et teknisk problem (f.eks. kan ikke logge ind, kan ikke afgive en ordre), så kontakt venligst kundeservice, så vi kan hjælpe dig direkte.',
        message: 'Din feedback',
        messagePlaceholder: 'Del dine idéer, forslag og feedback for at gøre portalen bedre...',
        attachments: 'Vedhæftede filer',
        optional: 'Valgfrit',
        uploadFile: 'Upload fil',
        dragDrop: 'eller træk og slip',
        fileTypes: 'PNG, JPG, PDF, DOC op til 10MB',
        submit: 'Send feedback',
        submitting: 'Sender...',
      },
      form: {
        success: 'Formularen blev sendt succesfuldt!',
        error: 'Kunne ikke sende formularen. Prøv venligst igen.',
      },
    },
  },
  no: {
    translation: {
      app: {
        subtitle: 'B2B Tilbakemelding Portal',
        footer: 'Alle rettigheter forbeholdt.',
      },
      feedback: {
        title: 'Feedback Form',
        description: 'Takk for at du hjelper oss å forbedre portalen!',
        usage: 'Vi samler inn idéer og forslag for å gjøre portalen bedre og enklere å bruke.',
        note: 'Merk: Hvis du har et teknisk problem (f.eks. kan ikke logge inn, kan ikke legge inn en bestilling), vennligst kontakt kundeservice så vi kan hjelpe deg direkte.',
        message: 'Din tilbakemelding',
        messagePlaceholder: 'Del dine idéer, forslag og tilbakemeldinger for å gjøre portalen bedre...',
        attachments: 'Vedlegg',
        optional: 'Valgfritt',
        uploadFile: 'Last opp fil',
        dragDrop: 'eller dra og slipp',
        fileTypes: 'PNG, JPG, PDF, DOC opptil 10MB',
        submit: 'Send tilbakemelding',
        submitting: 'Sender...',
      },
      form: {
        success: 'Skjemaet ble sendt vellykket!',
        error: 'Kunne ikke sende skjemaet. Vennligst prøv igjen.',
      },
    },
  },
  fi: {
    translation: {
      app: {
        subtitle: 'B2B Palaute Portaali',
        footer: 'Kaikki oikeudet pidätetään.',
      },
      feedback: {
        title: 'Feedback Form',
        description: 'Kiitos kun autat meitä parantamaan portaalia!',
        usage: 'Keräämme ideoita ja ehdotuksia tehdäksemme portaalista paremman ja helppokäyttöisemmän.',
        note: 'Huomaa: Jos sinulla on tekninen ongelma (esim. et voi kirjautua sisään, et voi tehdä tilausta), ota yhteyttä asiakaspalveluun, jotta voimme auttaa sinua suoraan.',
        message: 'Sinun palautteesi',
        messagePlaceholder: 'Jaa ideasi, ehdotuksesi ja palautteesi tehdäksesi portaalista paremman...',
        attachments: 'Liitteet',
        optional: 'Valinnainen',
        uploadFile: 'Lataa tiedosto',
        dragDrop: 'tai vedä ja pudota',
        fileTypes: 'PNG, JPG, PDF, DOC enintään 10MB',
        submit: 'Lähetä palaute',
        submitting: 'Lähetetään...',
      },
      form: {
        success: 'Lomake lähetetty onnistuneesti!',
        error: 'Lomakkeen lähettäminen epäonnistui. Yritä uudelleen.',
      },
    },
  },
};

i18n.use(initReactI18next).init({
  resources,
  lng: 'sv',
  fallbackLng: 'en',
  interpolation: {
    escapeValue: false,
  },
});

export default i18n;
