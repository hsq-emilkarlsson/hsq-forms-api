// apps/form-feedback/vite.config.ts
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
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
