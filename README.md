🚀 Frontend Despacho — Innovatech Chile

Aplicación React + Vite para la gestión de despachos y ventas, containerizada con Docker y 
desplegada automáticamente en Amazon ECS Fargate mediante un pipeline moderno de GitHub Actions.

🏗️ Arquitectura de Red y Despliegue (Cloud-Native)                  

                        INTERNET (Usuarios)
                                │
                                ▼ Puerto 80 / 443
                ┌───────────────────────────────┐
                │   Application Load Balancer   │
                │        (AWS ALB Shared)       │
                └───────┬───────┬───────┬───────┘
                        │       │       │
      ┌─────────────────┘       │       └─────────────────┐
      │ /                       │ /api/v1/ventas          │ /api/v1/despachos
      ▼ (Puerto 8080)           ▼ (Puerto 8081)           ▼ (Puerto 8082)
┌───────────────────┐     ┌───────────────────┐     ┌───────────────────┐
│    ECS Fargate    │     │    ECS Fargate    │     │    ECS Fargate    │
│  Servicio: Front  │     │  Servicio: Ventas │     │Servicio: Despachos│
│Contenedor: Nginx  │     │Contenedor: Spring │     │Contenedor: Spring │
│ (Archivos Fijos)  │     └─────────┬─────────┘     └─────────┬─────────┘
└───────────────────┘               │                         │
                                    └───────────┬─────────────┘
                                                ▼ (Puerto 3306)
                                    ┌───────────────────┐
                                    │    Amazon RDS     │
                                    │  Aurora / MySQL   │
                                    └───────────────────┘


⚙️ Cómo ejecutar en Desarrollo Local
Sin Docker (Proxy local de Vite)
Bash
# Instalar dependencias
npm install

# Levantar servidor de desarrollo 
npm run dev


# (Vite emula el ruteo local usando proxy configurado en vite.config.js hacia los puertos correspondientes)
Con Docker localBash# Construir y levantar todo el ecosistema (Frontend + APIs + DB)
docker compose up -d --build


☁️ Pipeline CI/CD (GitHub Actions)El despliegue ya no utiliza conexiones frágiles por SSH (appleboy). Ahora está completamente guiado por el API de AWS:

Trigger: push a la rama deploy


git push origin deploy
        │
        ▼
GitHub Actions (Workflow AWS Serverless)
        │
        ├─ 1. Checkout del código fuente
        ├─ 2. Configurar Credenciales de AWS (Soporte AWS Academy Session Token)
        ├─ 3. Login automático en Amazon ECR (Elastic Container Registry)
        ├─ 4. Build de la imagen Docker de producción
        ├─ 5. Push de la imagen inmutable a Amazon ECR
        ├─ 6. Actualizar AWS ECS Task Definition (Inyección de contenedores y puertos)
        └─ 7. Despliegue en Amazon ECS (Rolling Update automático en el Servicio)

        
🔐 Secrets de GitHub Actions RequeridosConfigurar en: Settings → Secrets and variables → Actions
Secret                                 Descripción / Uso
AWS_ACCESS_KEY_ID                      Clave de acceso de la cuenta 
AWSAWS_SECRET_ACCESS_KEY               Clave secreta de la cuenta 
AWSAWS_SESSION_TOKEN                   Token de sesión temporal requerido por laboratorios
AWS AcademyAWS_REGION                  Región asignada en AWS (ej: us-east-1)

📁 Estructura Actualizada del Repositoriofrontend/
├── .github/
│   └── workflows/
│       └── deploy.yml          ← Pipeline CI/CD nativo de AWS ECS
├── src/
│   ├── config/
│   │   └── api.js              ← URLs dinámicas relativas para aprovechar el ALB
│   ├── componentes/
│   │   ├── CrudAdmin/
│   │   └── Layouts/
│   └── main.jsx
├── Dockerfile                  ← Multi-stage build optimizado para ECS
├── nginx.conf                  ← Configuración simplificada (Solo lectura de estáticos)
├── docker-compose.yml          ← Orquestación de entorno de desarrollo local
├── vite.config.js              ← Configuración con proxy de desarrollo
└── README.md
