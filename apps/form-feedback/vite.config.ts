// apps/form-feedback/vite.config.ts
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  server: {
    host: true,
    port: 3001 // Use 3001 for feedback form to avoid 5173 conflict
  }
});