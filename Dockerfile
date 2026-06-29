# =============================================================
# STAGE 1: Builder — instala dependencias y compila el frontend
# =============================================================
FROM node:20-alpine AS builder

WORKDIR /app

# Copiar package files primero para aprovechar cache de capas Docker
# Si package.json no cambia, esta capa se cachea y el build es más rápido
COPY package*.json ./

# Instalar dependencias (ci = instalación limpia y reproducible)
RUN npm ci

# Copiar el resto del código fuente
COPY . .

# Build args para las URLs de los backends (se inyectan en tiempo de build)
# En producción con nginx proxy, quedan vacíos (llamadas relativas)
ARG VITE_VENTAS_URL=""
ARG VITE_DESPACHOS_URL=""
ENV VITE_VENTAS_URL=$VITE_VENTAS_URL
ENV VITE_DESPACHOS_URL=$VITE_DESPACHOS_URL

# Construir la aplicación React para producción
RUN npm run build

# =============================================================
# STAGE 2: Runner — imagen Nginx mínima para servir el build
# =============================================================
FROM nginx:1.25-alpine AS runner

# Crear grupo y usuario no root por seguridad (principio mínimo privilegio)
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Copiar el build generado desde el stage anterior
COPY --from=builder /app/dist /usr/share/nginx/html

# Copiar la plantilla de configuración Nginx
# El nginx oficial procesa /etc/nginx/templates/*.template en arranque
# sustituyendo variables de entorno con envsubst
COPY nginx.conf.template /etc/nginx/templates/default.conf.template

# Ajustar permisos para usuario no root
# Nota: /etc/nginx/conf.d necesita write para que el entrypoint pueda
# procesar las templates con envsubst al arrancar
RUN chown -R appuser:appgroup /usr/share/nginx/html && \
    chown -R appuser:appgroup /var/cache/nginx && \
    chown -R appuser:appgroup /var/log/nginx && \
    chown -R appuser:appgroup /etc/nginx/conf.d && \
    touch /var/run/nginx.pid && \
    chown appuser:appgroup /var/run/nginx.pid

# Cambiar a usuario no root
USER appuser

# Puerto de escucha
EXPOSE 8080

# Nginx se mantiene en foreground
CMD ["nginx", "-g", "daemon off;"]
