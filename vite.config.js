import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react-swc'

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [react()],

  server: {
    // Proxy para desarrollo local: evita CORS y simula el proxy de nginx
    proxy: {
      // Ventas API → Spring Boot en localhost:8080
      '/api/v1/ventas': {
        target: 'http://localhost:8080',
        changeOrigin: true,
      },
      // Despachos API → Spring Boot en localhost:8081
      '/api/v1/despachos': {
        target: 'http://localhost:8081',
        changeOrigin: true,
      }
    }
  }
})
