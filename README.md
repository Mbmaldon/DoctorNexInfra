# VitaNex Infra

Repositorio de infraestructura para el ecosistema **VitaNex**. Contiene la configuración de entorno local para desarrollo.

## Repositorios del proyecto

| Repo | Descripción | Puerto |
|---|---|---|
| `VitaNexInfra` | Este repo — infraestructura local | — |
| `VitaCareBackendAuth` | Microservicio de autenticación | 3000 |
| `VitaCareBackendCore` | Microservicio core del negocio | 3001 |
| `VitaCareFrontend` | Aplicación frontend | 4200 |

## Requisitos

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) instalado y corriendo
- [Node.js](https://nodejs.org) v22+ (recomendado vía [nvm](https://github.com/nvm-sh/nvm))

## Setup inicial (primera vez)

### 1. Configurar variables de entorno

```bash
cp .env.example .env
```

> En desarrollo el `.env.example` ya tiene los valores correctos, no necesitas cambiar nada.

### 2. Levantar la base de datos

```bash
docker compose up -d
```

Esto crea automáticamente:
- Base de datos `vita_nex_auth` (Auth Service)
- Base de datos `vita_nex_core` (Core Service)
- Usuario `vitanex` con acceso a ambas bases

### 3. Correr cada microservicio

En terminales separados, dentro de cada repo:

```bash
# Auth Service
cd ../VitaCareBackendAuth
npm install
npm run start:dev

# Core Service
cd ../VitaCareBackendCore
npm install
npm run start:dev

# Frontend
cd ../VitaCareFrontend
npm install
npm start
```

## Uso diario

```bash
# Al iniciar el día
docker compose up -d

# Al terminar (opcional, los datos persisten)
docker compose down
```

## Agregar un nuevo microservicio

1. Editar `docker/init.sql` y agregar el `CREATE DATABASE` correspondiente
2. Recrear el contenedor:
   ```bash
   docker compose down -v
   docker compose up -d
   ```
3. Agregar el nuevo repo a la tabla de este README

## Producción

En producción **no se usa este docker-compose**. Cada microservicio se conecta a una base de datos administrada (AWS RDS, DigitalOcean Managed MySQL, Railway, etc.) mediante la variable de entorno `DATABASE_URL` configurada en el host.
