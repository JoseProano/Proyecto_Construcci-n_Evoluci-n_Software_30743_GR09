"""
AmazonFish Backend – Aplicación Principal FastAPI
Sistema de Gestión Acuícola | GR09 | Construcción y Evolución de Software
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from database import engine, Base
from routers import auth, personas, usuarios, roles, proveedores, productos_acuicola, pedidos, ventas
import version

# Crea las tablas en la base de datos al iniciar (útil para SQLite en tests)
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="🐟 AmazonFish API",
    description=(
        "Backend del **Sistema de Gestión Acuícola AmazonFish** – GR09\n\n"
        "Módulos: Personas, Usuarios, Roles, Proveedores, Productos Acuícolas, Pedidos, Ventas.\n\n"
        "**Universidad de las Fuerzas Armadas ESPE** | Construcción y Evolución de Software | NRC 30743"
    ),
    version=version.VERSION,
    docs_url="/api/docs",
    redoc_url="/api/redoc",
    openapi_url="/api/openapi.json",
)

# ── CORS ──────────────────────────────────────────────────────────
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Routers ───────────────────────────────────────────────────────
app.include_router(auth.router,              prefix="/api/v1/auth",       tags=["🔐 Autenticación"])
app.include_router(personas.router,          prefix="/api/v1/personas",   tags=["👤 Personas"])
app.include_router(usuarios.router,          prefix="/api/v1/usuarios",   tags=["🧑‍💻 Usuarios"])
app.include_router(roles.router,             prefix="/api/v1/roles",      tags=["🛡️ Roles"])
app.include_router(proveedores.router,       prefix="/api/v1/proveedores",tags=["🚚 Proveedores"])
app.include_router(productos_acuicola.router,prefix="/api/v1/productos",  tags=["🐠 Productos Acuícolas"])
app.include_router(pedidos.router,            prefix="/api/v1/pedidos",    tags=["🛒 Pedidos"])
app.include_router(ventas.router,             prefix="/api/v1/ventas",     tags=["💵 Ventas"])


# ── Endpoints de salud ────────────────────────────────────────────

@app.get("/", tags=["❤️ Health"])
def root():
    """Información general del servicio."""
    return {
        "sistema": "AmazonFish API",
        "version": version.VERSION,
        "build_date": version.BUILD_DATE,
        "grupo": "GR09",
        "nrc": "30743",
        "estado": "operativo",
        "docs": "/api/docs",
    }


@app.get("/health", tags=["❤️ Health"])
def health_check():
    """Health check para Render / monitoreo."""
    return {"status": "healthy", "service": "amazonfish-backend"}
