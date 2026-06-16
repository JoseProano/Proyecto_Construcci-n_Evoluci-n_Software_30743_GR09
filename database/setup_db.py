"""
AmazonFish – Script de Inicialización de Base de Datos
Ejecuta los esquemas SQL en Supabase y crea el usuario administrador inicial.

Uso:
    cd Proyecto_AmazonFish
    python database/setup_db.py

Requisito: Variable DATABASE_URL configurada en backend/.env
"""
import sys
import os

# Agregar backend al path para importar módulos
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'backend'))

from database import SessionLocal, engine
from models import Base, Rol, Persona, Usuario, UsuarioRol
from security import get_password_hash


def run_migrations():
    """Crea todas las tablas según los modelos SQLAlchemy."""
    print("📦 Creando tablas en la base de datos...")
    Base.metadata.create_all(bind=engine)
    print("✅ Tablas creadas correctamente.")


def seed_initial_data():
    """Inserta datos iniciales si no existen."""
    db = SessionLocal()
    try:
        # ── Roles ─────────────────────────────────────────────────
        roles_data = [
            ("administrador", "Control total: inventario, ventas, reportes y configuración"),
            ("vendedor",      "Armar pedidos, registrar cobros y consultar inventario"),
            ("socio",         "Cliente acuícola: ver catálogo y su historial"),
        ]
        roles_map = {}
        for nombre, desc in roles_data:
            existing = db.query(Rol).filter(Rol.nombre == nombre).first()
            if not existing:
                rol = Rol(nombre=nombre, descripcion=desc)
                db.add(rol)
                db.flush()
                roles_map[nombre] = rol
                print(f"  ✅ Rol creado: {nombre}")
            else:
                roles_map[nombre] = existing
                print(f"  ℹ️  Rol ya existe: {nombre}")

        # ── Persona administrador ─────────────────────────────────
        persona_admin = db.query(Persona).filter(
            Persona.identificacion == "0000000001"
        ).first()

        if not persona_admin:
            persona_admin = Persona(
                nombres="Admin",
                apellidos="AmazonFish",
                identificacion="0000000001",
                correo="admin@amazonfish.com",
                telefono="0999000000",
            )
            db.add(persona_admin)
            db.flush()
            print("  ✅ Persona administrador creada.")

            # ── Usuario administrador ──────────────────────────────
            usuario_admin = Usuario(
                id_persona=persona_admin.id_persona,
                username="admin",
                password_hash=get_password_hash("Amazon2026!"),
            )
            db.add(usuario_admin)
            db.flush()
            print("  ✅ Usuario administrador creado.")
            print("     👤 Username: admin")
            print("     🔑 Password: Amazon2026!")

            # ── Asignar rol administrador ──────────────────────────
            ur = UsuarioRol(
                id_usuario=usuario_admin.id_usuario,
                id_rol=roles_map["administrador"].id_rol,
            )
            db.add(ur)
            print("  ✅ Rol administrador asignado.")
        else:
            print("  ℹ️  Usuario administrador ya existe.")

        db.commit()
        print("\n🎉 Base de datos inicializada correctamente.")

    except Exception as e:
        db.rollback()
        print(f"\n❌ Error al inicializar: {e}")
        raise
    finally:
        db.close()


if __name__ == "__main__":
    print("=" * 60)
    print("🐟 AmazonFish – Setup de Base de Datos")
    print("=" * 60)
    run_migrations()
    seed_initial_data()
    print("=" * 60)
