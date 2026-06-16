# 🐟 AmazonFish – Sistema de Gestión Acuícola

[![CI/CD Pipeline](https://github.com/JoseProano/Proyecto_Construcci-n_Evoluci-n_Software_30743_GR09/actions/workflows/ci-cd.yml/badge.svg)](https://github.com/JoseProano/Proyecto_Construcci-n_Evoluci-n_Software_30743_GR09/actions)
[![Quality Gate Status](https://sonarcloud.io/api/project_badges/measure?project=amazonfish-gr09&metric=alert_status)](https://sonarcloud.io/project/overview?id=amazonfish-gr09)
[![Coverage](https://sonarcloud.io/api/project_badges/measure?project=amazonfish-gr09&metric=coverage)](https://sonarcloud.io/project/overview?id=amazonfish-gr09)

**Universidad de las Fuerzas Armadas ESPE** | Construcción y Evolución de Software | NRC 30743 | **GR09**

> Sistema de gestión integral para el negocio acuícola AmazonFish: control de inventario, pedidos, ventas, proveedores y reportes.

---

## 🔗 Links Importantes

| Recurso | URL |
|---------|-----|
| 🌐 Landing Page (Frontend) | https://joseproano.github.io/Proyecto_Construcci-n_Evoluci-n_Software_30743_GR09/ |
| ⚡ Backend API (Render) | https://amazonfish-backend.onrender.com/api/docs |
| 📱 Descargar APK | [Última Release](https://github.com/JoseProano/Proyecto_Construcci-n_Evoluci-n_Software_30743_GR09/releases/latest) |
| 🔍 SonarCloud | https://sonarcloud.io/project/overview?id=amazonfish-gr09 |
| ⚙️ GitHub Actions | [Ver Pipeline](https://github.com/JoseProano/Proyecto_Construcci-n_Evoluci-n_Software_30743_GR09/actions) |

---

## 🏗️ Arquitectura

```
App Flutter (Android)
        │
        │ HTTPS / JWT
        ▼
FastAPI Backend ────────→ Supabase PostgreSQL
(Render)                  (qzumnczcygjsszxbmhqk)
```

## 📁 Estructura del Proyecto

```
Proyecto_AmazonFish/
├── .github/workflows/
│   └── ci-cd.yml           # Pipeline CI/CD completo
├── app/                    # Flutter app móvil (Android)
│   ├── lib/
│   │   ├── main.dart
│   │   ├── screens/        # login, admin, vendedor, socio
│   │   └── services/       # api_service, auth
│   └── test/
├── backend/                # FastAPI microservicio
│   ├── main.py
│   ├── models.py           # SQLAlchemy + herencia
│   ├── schemas.py          # Pydantic v2
│   ├── security.py         # JWT + bcrypt
│   ├── routers/            # auth, personas, usuarios, roles, productos
│   ├── services/
│   │   └── producto_factory.py  # Factory Method Pattern
│   └── tests/              # pytest (SQLite in-memory)
├── database/
│   ├── 01_schema_personas_usuarios_roles.sql
│   ├── 02_schema_dominio_amazonfish.sql
│   └── setup_db.py         # Script de inicialización
├── docs/                   # GitHub Pages landing
│   └── index.html
├── scripts/                # Scripts de prueba del pipeline
│   ├── trigger_pass.py
│   ├── trigger_fail.py
│   └── cleanup_fail.py
├── sonar-project.properties
└── render.yaml
```

---

## 🚀 Flujo DevOps

```
Commit → GitHub → GitHub Actions:
  1. 📢 Notificación Telegram (inicio)
  2. 🧪 Tests backend (pytest + coverage)
  3. 🔍 SonarCloud (bugs, vulnerabilidades, code smells)
  4. 📱 Build APK Flutter
  5. 🚀 Deploy Backend → Render  (solo main)
  6. 🏷️ Release GitHub con APK  (solo main)
  7. 🌐 Deploy GitHub Pages      (solo main)
  8. 📢 Notificación Telegram (resultado)
```

---

## 🌿 Ramas (Git Flow)

| Rama | Propósito |
|------|-----------|
| `main` | Producción. Solo se mergea tras PR aprobado. Dispara deploy completo. |
| `develop` | Integración continua. Dispara tests + SonarCloud. |
| `feature/personas-usuarios-roles` | Módulo obligatorio del segundo parcial. |

---

## 📋 Módulo Obligatorio: Personas, Usuarios y Roles

Cumple todas las reglas de la rúbrica:

- ✅ **Persona separada de Usuario** (datos personales ≠ credenciales)
- ✅ **Persona 1:1 Usuario** (UNIQUE constraint en id_persona)
- ✅ **Usuario N:M Rol** (tabla intermedia `usuario_rol`)
- ✅ **UUID como clave primaria** en todas las entidades
- ✅ **password_hash** con bcrypt (NUNCA texto plano)
- ✅ **CRUD completo**: crear persona, crear usuario, crear rol, asignar roles, listar usuarios con roles

## 🐠 Módulo de Dominio: Proveedores y Productos Acuícolas

- ✅ **Herencia**: `Proveedor → PersonaNatural | PersonaJuridica`
- ✅ **Herencia**: `ProductoAcuicola → Balanceado | InsumoAcuicola | MedicamentoAcuicola | EquipoAcuicola`
- ✅ **Factory Method**: código dinámico `PROD-BAL-2026-0001`, `PROD-INS-2026-0002`…
- ✅ **UUID** como clave primaria

---

## ⚙️ Configurar GitHub Secrets

Ve a: **GitHub repo → Settings → Secrets and variables → Actions → New repository secret**

| Secret | Valor |
|--------|-------|
| `DATABASE_URL` | La URL de conexión del Pooler de Supabase (`postgresql://postgres.<ID_PROYECTO>:<PASSWORD>@<HOST_POOLER>:6543/postgres`) |
| `SECRET_KEY` | Una cadena aleatoria larga para firmas JWT (ej: `amazonfish-gr09-jwt-secret-2026-muy-seguro`) |
| `TELEGRAM_BOT_TOKEN` | El token HTTP de tu bot de Telegram obtenido con @BotFather |
| `TELEGRAM_CHAT_ID` | Tu ID de chat de Telegram obtenido con @userinfobot |
| `SONAR_TOKEN` | El token de acceso generado desde SonarCloud en My Account → Security |
| `RENDER_DEPLOY_HOOK_URL` | La URL de despliegue obtenida de Render en Settings → Deploy Hook |
| `API_BASE_URL` | La URL de producción de tu backend en Render (ej: `https://amazonfish-backend.onrender.com`) |

---

## 🔍 Configurar SonarCloud

1. Ve a [sonarcloud.io](https://sonarcloud.io) → Iniciar sesión con GitHub
2. Haz clic en **"+"** → **"Analyze new project"**
3. Selecciona el repositorio `Proyecto_Construcci-n_Evoluci-n_Software_30743_GR09`
4. En la configuración, selecciona **"With GitHub Actions"**
5. Cuando te pida el project key, usa: `amazonfish-gr09`
6. Organization key: `joseproano`
7. Copia el `SONAR_TOKEN` generado y regístralo en tus Secrets de GitHub.

---

## 🚀 Configurar Render (Backend)

1. Ve a [render.com](https://render.com) → Crea cuenta con GitHub
2. **New** → **Web Service**
3. Conecta el repositorio de GitHub
4. Configuración:
   - **Name**: `amazonfish-backend`
   - **Root Directory**: `backend`
   - **Build Command**: `pip install -r requirements.txt`
   - **Start Command**: `uvicorn main:app --host 0.0.0.0 --port $PORT`
   - **Plan**: Free
5. En **Environment Variables**, agrega:
   - `DATABASE_URL` = (la connection string de Supabase)
   - `SECRET_KEY` = (la misma del GitHub Secret)
6. En **Settings** → copia el **Deploy Hook URL** y agrégalo como `RENDER_DEPLOY_HOOK_URL` en GitHub Secrets

---

## 🧪 Ejecutar tests localmente

```bash
cd backend
pip install -r requirements.txt
pytest tests/ -v --cov=. --cov-report=term
```

---

## 🏃 Inicializar la base de datos

```bash
# Configura DATABASE_URL primero en backend/.env
cd Proyecto_AmazonFish
python database/setup_db.py
```

Credenciales iniciales: `admin` / `Amazon2026!`

---

## 👥 Equipo

| Nombre | Rol |
|--------|-----|
| Jonathan García | Desarrollador / Gerente de Proyecto |
| José Proaño | Desarrollador / Arquitecto de Software |

---

*GR09 · NRC 30743 · Universidad de las Fuerzas Armadas ESPE · 2026*
