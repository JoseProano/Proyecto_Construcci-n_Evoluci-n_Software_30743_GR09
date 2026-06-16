"""
AmazonFish – Test Fixtures (conftest.py)
Configura una base de datos SQLite en memoria para tests,
sin necesidad de conexión a Supabase en CI/CD.
"""
import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from database import Base, get_db
from main import app
from models import Rol, Persona, Usuario, UsuarioRol
from security import get_password_hash

# ── Base de datos SQLite para tests ──────────────────────────────
SQLALCHEMY_TEST_URL = "sqlite:///./test_amazonfish.db"

engine_test = create_engine(
    SQLALCHEMY_TEST_URL,
    connect_args={"check_same_thread": False},
)
TestingSession = sessionmaker(autocommit=False, autoflush=False, bind=engine_test)


def _seed(db) -> None:
    """Inserta datos iniciales de prueba."""
    # Roles
    for nombre, desc in [
        ("administrador", "Control total"),
        ("vendedor", "Ventas y pedidos"),
        ("socio", "Cliente del negocio"),
    ]:
        if not db.query(Rol).filter(Rol.id_rol == f"rol-{nombre[:5]}-001").first():
            db.add(Rol(id_rol=f"rol-{nombre[:5]}-001", nombre=nombre, descripcion=desc))

    # Persona de prueba
    if not db.query(Persona).filter(Persona.id_persona == "persona-test-001").first():
        db.add(Persona(
            id_persona="persona-test-001",
            nombres="Admin",
            apellidos="Test",
            identificacion="9999999999",
            correo="admin@test.amazonfish.com",
        ))

    # Usuario de prueba (contraseña: admin123)
    if not db.query(Usuario).filter(Usuario.id_usuario == "usuario-test-001").first():
        db.add(Usuario(
            id_usuario="usuario-test-001",
            id_persona="persona-test-001",
            username="admin_test",
            password_hash=get_password_hash("admin123"),
        ))

    # Asignar rol administrador
    if not db.query(UsuarioRol).filter(UsuarioRol.id_usuario_rol == "ur-test-001").first():
        db.add(UsuarioRol(
            id_usuario_rol="ur-test-001",
            id_usuario="usuario-test-001",
            id_rol="rol-admin-001",
        ))

    db.commit()


@pytest.fixture(scope="session", autouse=True)
def setup_database():
    """Crea las tablas antes de los tests y las elimina al finalizar."""
    Base.metadata.create_all(bind=engine_test)
    yield
    Base.metadata.drop_all(bind=engine_test)


@pytest.fixture(scope="function")
def db(setup_database):
    """Provee una sesión de base de datos con rollback automático por test."""
    connection = engine_test.connect()
    transaction = connection.begin()
    session = TestingSession(bind=connection)
    _seed(session)
    yield session
    session.close()
    transaction.rollback()
    connection.close()


@pytest.fixture(scope="function")
def client(db):
    """Cliente HTTP de FastAPI con DB de test inyectada."""
    app.dependency_overrides[get_db] = lambda: db
    with TestClient(app) as c:
        yield c
    app.dependency_overrides.clear()


@pytest.fixture(scope="function")
def auth_headers(client) -> dict:
    """Headers de autenticación para el usuario admin de prueba."""
    resp = client.post("/api/v1/auth/login", json={
        "username": "admin_test",
        "password": "admin123",
    })
    assert resp.status_code == 200, f"Login failed: {resp.text}"
    return {"Authorization": f"Bearer {resp.json()['access_token']}"}
