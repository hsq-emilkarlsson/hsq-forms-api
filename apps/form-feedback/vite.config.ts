// apps/form-feedback/vite.config.ts
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import { resolve } from 'path';

export default defineConfig({
  plugins: [
    react(),
  ],
  // Explicitly set base path to root for Azure SWA
  base: '/',
  // Make sure Vite knows we're building an SPA
  appType: 'spa',
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
      // Make sure we use index.html as the entry point
      input: {
        main: resolve(__dirname, 'index.html'),
      },
      output: {
        // Make sure chunks are correctly named and hashed
        manualChunks: {
          react: ['react', 'react-dom'],
          router: ['react-router-dom']
        },
        // Force clean asset output paths that work well with Azure SWA
        entryFileNames: 'assets/[name].[hash].js',
        chunkFileNames: 'assets/[name].[hash].js',
        assetFileNames: 'assets/[name].[hash].[ext]'
      }
    },
    // Ensure proper handling of JSX imports
    target: 'es2015'
  },
  resolve: {
    alias: {
      '@': '/src'
    }
  },
  // Ensure static file copying
  publicDir: 'public'
});
