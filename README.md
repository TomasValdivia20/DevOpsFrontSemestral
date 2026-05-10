# Frontend Despacho — Innovatech Chile 

Aplicación React + Vite para la gestión de despachos y ventas, containerizada con Docker y desplegada automáticamente en AWS EC2 mediante GitHub Actions.

##  Arquitectura

```
INTERNET
    │  Puerto 80
    ▼
┌─────────────────────────────┐
│   EC2 Frontend (pública)    │
│   Contenedor: nginx         │
│   Sirve SPA + Proxy API     │
└────────────┬────────────────┘
             │ /api/v1/ventas    → :8080
             │ /api/v1/despachos → :8081
             │ (Red privada VPC)
             ▼
┌─────────────────────────────┐
│   EC2 Backend (privada)     │
│   Contenedor: ventas :8080  │
│   Contenedor: despachos:8081│
│   Contenedor: mysql :3306   │
│   Volumen: mysql-data       │
└─────────────────────────────┘
```

> **Solo el Frontend EC2 es accesible desde Internet.**  
> El Backend EC2 solo recibe tráfico del Frontend (Security Group).

##  Stack Tecnológico

| Capa | Tecnología | Versión |
|---|---|---|
| Framework UI | React | 18.2 |
| Build tool | Vite + SWC | 5.2 |
| Estilos | Tailwind CSS | 3.4 |
| HTTP Client | Axios | 1.6 |
| Forms | React Hook Form | 7.52 |
| Alertas | SweetAlert2 | 11 |
| Servidor web | Nginx | 1.25 Alpine |
| Runtime build | Node.js | 20 Alpine |

##  Decisiones técnicas del Dockerfile

| Característica | Decisión | Justificación |
|---|---|---|
| Multi-stage build |  Stage builder + runner | Imagen final solo contiene el build estático, no node_modules (~80% más pequeña) |
| Usuario no root |  `appuser:appgroup` | Principio mínimo privilegio: si comprometen el contenedor, no obtienen root del host |
| Cache de capas |  `package*.json` copiado primero | Si solo cambia código fuente, la instalación de npm se cachea |
| Imagen base runtime | `nginx:1.25-alpine` | Alpine = mínimo tamaño (~7MB), menos superficie de ataque |
| Proxy API |  Nginx proxy_pass | Backend nunca expuesto directamente a Internet |

##  Cómo ejecutar

### Desarrollo local (sin Docker)
```bash
# Instalar dependencias
npm install

# Levantar servidor de desarrollo (proxy configurado en vite.config.js)
npm run dev
# Vite proxea /api/v1/ventas → localhost:8080
# Vite proxea /api/v1/despachos → localhost:8081
```

### Con Docker local
```bash
# Copiar y configurar variables de entorno
cp .env.example .env
# Si los backends corren en otra máquina, editar BACKEND_HOST=<IP>

# Construir y levantar
docker compose up -d --build

# Ver logs
docker compose logs -f

# Verificar que corre
curl http://localhost
```

### En producción (EC2)
El pipeline CI/CD se encarga de todo. Ver sección CI/CD más abajo.

##  Variables de entorno

| Variable | Descripción | Default producción |
|---|---|---|
| `VITE_VENTAS_URL` | URL base API Ventas (bakeada en build) | `""` (vacío = relativa) |
| `VITE_DESPACHOS_URL` | URL base API Despachos (bakeada en build) | `""` (vacío = relativa) |
| `BACKEND_HOST` | IP privada EC2 Backend (para nginx proxy) | Requerida en producción |

##  Pipeline CI/CD

Trigger: **push a la rama `deploy`**

```
git push origin deploy
        │
        ▼
GitHub Actions
        │
        ├─ 1. Checkout código
        ├─ 2. Docker Buildx
        ├─ 3. Login Docker Hub (secret)
        ├─ 4. Build imagen multi-stage
        ├─ 5. Push a Docker Hub
        │
        └─ 6. SSH al EC2 Frontend
              ├─ docker pull imagen:latest
              ├─ docker stop/rm contenedor anterior
              ├─ docker run con BACKEND_HOST
              └─ docker image prune
```

### Secrets de GitHub Actions requeridos

Configurar en: Settings → Secrets and variables → Actions

| Secret | Descripción |
|---|---|
| `DOCKERHUB_USERNAME` | Usuario de Docker Hub |
| `DOCKERHUB_TOKEN` | Access Token de Docker Hub |
| `EC2_FRONTEND_HOST` | IP pública del EC2 Frontend |
| `EC2_USER` | `ubuntu` |
| `EC2_SSH_KEY` | Contenido completo del archivo `.pem` |
| `BACKEND_PRIVATE_IP` | IP privada del EC2 Backend en la VPC |

##  Flujo de trabajo Git

```bash
# Desarrollar en main
git checkout main
# ... cambios ...
git add . && git commit -m "feat: descripción del cambio"
git push origin main

# Desplegar en producción: merge a deploy
git checkout deploy
git merge main
git push origin deploy   ← ESTO ACTIVA EL PIPELINE
```

##  Estructura del repositorio

```
frontend/
├── .github/
│   └── workflows/
│       └── deploy.yml          ← Pipeline CI/CD
├── src/
│   ├── config/
│   │   └── api.js              ← URLs centralizadas de APIs
│   ├── componentes/
│   │   ├── CrudAdmin/
│   │   │   ├── TableCompras.jsx
│   │   │   ├── TableDespachos.jsx
│   │   │   ├── FormDespacho.jsx
│   │   │   └── FormCierreDespacho.jsx
│   │   └── Layouts/
│   ├── Routes/
│   └── main.jsx
├── Dockerfile                  ← Multi-stage build
├── nginx.conf.template         ← Configuración nginx con proxy
├── docker-compose.yml          ← Orquestación local/producción
├── vite.config.js              ← Config Vite con proxy dev
├── .env.example                ← Plantilla variables de entorno
└── README.md
```
