import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
    host: true
  },
  build: {
    rollupOptions: {
      output: {
        manualChunks: {
          'vendor-react': ['react', 'react-dom'],
          'vendor-xlsx': ['xlsx'],
          'vendor-supabase': ['@supabase/supabase-js'],
          'vendor-icons': ['lucide-react']
        }
      }
    },
    chunkSizeWarningLimit: 800
  }
})
