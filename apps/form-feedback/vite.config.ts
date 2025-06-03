// apps/form-feedback/vite.config.ts
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import { resolve } from 'path';

export default defineConfig({
  plugins: [react()],
  // Explicitly set base path to root for Azure SWA
  base: '/',
  // Main entry point for the application
  appType: 'spa', // Make sure Vite knows we're building an SPA
  server: {
    host: true,
    port: 3001, // Use 3001 for feedback form to avoid 5173 conflict
    // Add history API fallback for SPA routing
    historyApiFallback: true
  },
  build: {
    outDir: 'dist',
    emptyOutDir: true,
    sourcemap: true,
    minify: 'terser', // Use Terser for better minification
    terserOptions: {
      compress: {
        drop_console: false, // Keep console logs for debugging
      },
    },
    rollupOptions: {
      input: {
        main: resolve(__dirname, 'index.html'),
      },
      output: {
        manualChunks: {
          react: ['react', 'react-dom'],
          router: ['react-router-dom']
        }
      }
    }
  },
  resolve: {
    alias: {
      '@': '/src'
    }
  },
  // Ensure static file copying
  publicDir: 'public'
});
