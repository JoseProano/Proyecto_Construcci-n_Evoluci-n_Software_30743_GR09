"""
AmazonFish Backend – Modelos SQLAlchemy
Implementa herencia (Proveedor y ProductoAcuicola) y relaciones Persona↔Usuario↔Rol.
Compatible con PostgreSQL (producción) y SQLite (tests CI).
"""
import uuid
from datetime import datetime
from sqlalchemy import (
    Column, String, Boolean, DateTime, ForeignKey,
    Numeric, Text, Integer, UniqueConstraint,
)
from sqlalchemy.orm import relationship
from database import Base


def _uuid() -> str:
    """Genera un UUID v4 como string (compatible SQLite + PostgreSQL)."""
    return str(uuid.uuid4())


# ════════════════════════════════════════════════════════════════
# MÓDULO: PERSONAS, USUARIOS Y ROLES
# Regla: Persona 1──1 Usuario, Usuario N──M Rol (vía UsuarioRol)
# ════════════════════════════════════════════════════════════════

class Rol(Base):
    """Rol del sistema (administrador, vendedor, socio)."""
    __tablename__ = "roles"

    id_rol = Column(String(36), primary_key=True, default=_uuid)
    nombre = Column(String(50), nullable=False, unique=True)
    descripcion = Column(Text)
    estado = Column(Boolean, nullable=False, default=True)
    fecha_creacion = Column(DateTime, default=datetime.utcnow)

    usuarios = relationship(
        "UsuarioRol", back_populates="rol", cascade="all, delete-orphan"
    )


class Persona(Base):
    """
    Entidad Persona – datos personales.
    Separada de Usuario para no mezclar datos personales con credenciales.
    """
    __tablename__ = "personas"

    id_persona = Column(String(36), primary_key=True, default=_uuid)
    nombres = Column(String(100), nullable=False)
    apellidos = Column(String(100), nullable=False)
    identificacion = Column(String(20), nullable=False, unique=True)
    correo = Column(String(150), nullable=False, unique=True)
    telefono = Column(String(20))
    estado = Column(Boolean, nullable=False, default=True)
    fecha_creacion = Column(DateTime, default=datetime.utcnow)

    # Relación 1:1 con Usuario (una persona tiene un único usuario)
    usuario = relationship(
        "Usuario", back_populates="persona", uselist=False, cascade="all, delete-orphan"
    )


class Usuario(Base):
    """
    Entidad Usuario – credenciales de acceso.
    NUNCA almacena contraseña en texto plano; usa password_hash (bcrypt).
    """
    __tablename__ = "usuarios"

    id_usuario = Column(String(36), primary_key=True, default=_uuid)
    id_persona = Column(
        String(36), ForeignKey("personas.id_persona"), nullable=False, unique=True
    )
    username = Column(String(50), nullable=False, unique=True)
    password_hash = Column(String(255), nullable=False)  # bcrypt hash
    estado = Column(Boolean, nullable=False, default=True)
    fecha_creacion = Column(DateTime, default=datetime.utcnow)
    ultimo_acceso = Column(DateTime, nullable=True)

    persona = relationship("Persona", back_populates="usuario")
    roles = relationship(
        "UsuarioRol", back_populates="usuario", cascade="all, delete-orphan"
    )


class UsuarioRol(Base):
    """
    Tabla intermedia N:M entre Usuario y Rol.
    Un usuario puede tener varios roles; un rol puede asignarse a varios usuarios.
    """
    __tablename__ = "usuario_rol"

    id_usuario_rol = Column(String(36), primary_key=True, default=_uuid)
    id_usuario = Column(
        String(36), ForeignKey("usuarios.id_usuario"), nullable=False
    )
    id_rol = Column(String(36), ForeignKey("roles.id_rol"), nullable=False)
    fecha_asignacion = Column(DateTime, default=datetime.utcnow)
    estado = Column(Boolean, nullable=False, default=True)

    usuario = relationship("Usuario", back_populates="roles")
    rol = relationship("Rol", back_populates="usuarios")

    __table_args__ = (
        UniqueConstraint("id_usuario", "id_rol", name="uq_usuario_rol"),
    )


# ════════════════════════════════════════════════════════════════
# MÓDULO DOMINIO: PROVEEDORES (Herencia – Joined Table)
# Proveedor → ProveedorPersonaNatural | ProveedorPersonaJuridica
# ════════════════════════════════════════════════════════════════

class Proveedor(Base):
    """Clase base abstracta para proveedores. Usa joined table inheritance."""
    __tablename__ = "proveedores"
    __mapper_args__ = {
        "polymorphic_on": "tipo_proveedor",
        "polymorphic_identity": "base",
    }

    id_proveedor = Column(String(36), primary_key=True, default=_uuid)
    razon_social = Column(String(200), nullable=False)
    correo = Column(String(150))
    telefono = Column(String(20))
    direccion = Column(Text)
    estado = Column(Boolean, nullable=False, default=True)
    tipo_proveedor = Column(String(20), nullable=False)  # discriminador
    fecha_registro = Column(DateTime, default=datetime.utcnow)

    productos = relationship("ProductoAcuicola", back_populates="proveedor")


class ProveedorPersonaNatural(Proveedor):
    """Proveedor que es una persona natural (con cédula)."""
    __tablename__ = "proveedores_persona_natural"
    __mapper_args__ = {"polymorphic_identity": "natural"}

    id_proveedor = Column(
        String(36), ForeignKey("proveedores.id_proveedor"), primary_key=True
    )
    nombres = Column(String(100))
    apellidos = Column(String(100))
    cedula = Column(String(20))


class ProveedorPersonaJuridica(Proveedor):
    """Proveedor que es una persona jurídica (empresa con RUC)."""
    __tablename__ = "proveedores_persona_juridica"
    __mapper_args__ = {"polymorphic_identity": "juridico"}

    id_proveedor = Column(
        String(36), ForeignKey("proveedores.id_proveedor"), primary_key=True
    )
    ruc = Column(String(15))
    nombre_comercial = Column(String(200))
    representante_legal = Column(String(200))


# ════════════════════════════════════════════════════════════════
# MÓDULO DOMINIO: PRODUCTOS ACUÍCOLAS (Herencia – Joined Table)
# ProductoAcuicola → Balanceado | InsumoAcuicola | MedicamentoAcuicola | EquipoAcuicola
# Código generado dinámicamente: PROD-BAL-2026-0001
# ════════════════════════════════════════════════════════════════

class ProductoAcuicola(Base):
    """Clase base abstracta para productos del negocio acuícola."""
    __tablename__ = "productos_acuicola"
    __mapper_args__ = {
        "polymorphic_on": "tipo_producto",
        "polymorphic_identity": "base",
    }

    id_producto = Column(String(36), primary_key=True, default=_uuid)
    # Código legible generado por Factory Method: PROD-BAL-2026-0001
    codigo_producto = Column(String(30), nullable=False, unique=True)
    nombre = Column(String(200), nullable=False)
    descripcion = Column(Text)
    precio_unitario = Column(Numeric(10, 2), nullable=False)
    stock_actual = Column(Numeric(10, 2), nullable=False, default=0)
    stock_minimo = Column(Numeric(10, 2), nullable=False, default=0)
    unidad_medida = Column(String(20), nullable=False, default="kg")
    estado = Column(Boolean, nullable=False, default=True)
    tipo_producto = Column(String(20), nullable=False)  # discriminador
    id_proveedor = Column(
        String(36), ForeignKey("proveedores.id_proveedor"), nullable=True
    )
    fecha_registro = Column(DateTime, default=datetime.utcnow)

    proveedor = relationship("Proveedor", back_populates="productos")


class Balanceado(ProductoAcuicola):
    """Alimento balanceado para acuicultura (tilapia, camarón, trucha…)."""
    __tablename__ = "balanceados"
    __mapper_args__ = {"polymorphic_identity": "balanceado"}

    id_producto = Column(
        String(36), ForeignKey("productos_acuicola.id_producto"), primary_key=True
    )
    tipo_especie = Column(String(50))  # tilapia | camarón | trucha
    etapa_vida = Column(String(50))    # iniciación | crecimiento | engorde


class InsumoAcuicola(ProductoAcuicola):
    """Insumo para el proceso productivo (probióticos, minerales…)."""
    __tablename__ = "insumos_acuicola"
    __mapper_args__ = {"polymorphic_identity": "insumo"}

    id_producto = Column(
        String(36), ForeignKey("productos_acuicola.id_producto"), primary_key=True
    )
    tipo_insumo = Column(String(50))
    aplicacion = Column(Text)


class MedicamentoAcuicola(ProductoAcuicola):
    """Medicamento veterinario para uso en acuicultura."""
    __tablename__ = "medicamentos_acuicola"
    __mapper_args__ = {"polymorphic_identity": "medicamento"}

    id_producto = Column(
        String(36), ForeignKey("productos_acuicola.id_producto"), primary_key=True
    )
    principio_activo = Column(String(100))
    dosis_recomendada = Column(String(100))
    registro_sanitario = Column(String(50))


class EquipoAcuicola(ProductoAcuicola):
    """Equipo y maquinaria para producción acuícola."""
    __tablename__ = "equipos_acuicola"
    __mapper_args__ = {"polymorphic_identity": "equipo"}

    id_producto = Column(
        String(36), ForeignKey("productos_acuicola.id_producto"), primary_key=True
    )
    marca = Column(String(50))
    modelo = Column(String(50))
    garantia_meses = Column(Integer)
