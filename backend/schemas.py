"""
AmazonFish Backend – Schemas Pydantic v2
Validación de entradas/salidas para la API REST.
"""
from pydantic import BaseModel, field_validator
from typing import Optional, List, Union
from datetime import datetime
from uuid import UUID

UUID_STR = Union[UUID, str]


# ════════════════════════════════════════════════════════════════
# PERSONA
# ════════════════════════════════════════════════════════════════

class PersonaBase(BaseModel):
    nombres: str
    apellidos: str
    identificacion: str
    correo: str
    telefono: Optional[str] = None
    estado: bool = True


class PersonaCreate(PersonaBase):
    pass


class PersonaUpdate(BaseModel):
    nombres: Optional[str] = None
    apellidos: Optional[str] = None
    correo: Optional[str] = None
    telefono: Optional[str] = None
    estado: Optional[bool] = None


class PersonaResponse(PersonaBase):
    id_persona: UUID_STR
    fecha_creacion: datetime

    model_config = {"from_attributes": True}


# ════════════════════════════════════════════════════════════════
# ROL
# ════════════════════════════════════════════════════════════════

class RolBase(BaseModel):
    nombre: str
    descripcion: Optional[str] = None
    estado: bool = True


class RolCreate(RolBase):
    pass


class RolUpdate(BaseModel):
    nombre: Optional[str] = None
    descripcion: Optional[str] = None
    estado: Optional[bool] = None


class RolResponse(RolBase):
    id_rol: UUID_STR
    fecha_creacion: datetime

    model_config = {"from_attributes": True}


# ════════════════════════════════════════════════════════════════
# USUARIO-ROL (tabla intermedia)
# ════════════════════════════════════════════════════════════════

class UsuarioRolResponse(BaseModel):
    id_usuario_rol: UUID_STR
    id_usuario: UUID_STR
    id_rol: UUID_STR
    fecha_asignacion: datetime
    estado: bool
    rol: Optional[RolResponse] = None

    model_config = {"from_attributes": True}


class AsignarRolSchema(BaseModel):
    id_usuario: UUID_STR
    id_rol: UUID_STR


# ════════════════════════════════════════════════════════════════
# USUARIO
# ════════════════════════════════════════════════════════════════

class UsuarioBase(BaseModel):
    username: str
    estado: bool = True


class UsuarioCreate(UsuarioBase):
    id_persona: UUID_STR
    password: str

    @field_validator("password")
    @classmethod
    def password_strength(cls, v: str) -> str:
        if len(v) < 8:
            raise ValueError("La contraseña debe tener al menos 8 caracteres")
        return v


class UsuarioUpdate(BaseModel):
    username: Optional[str] = None
    estado: Optional[bool] = None
    password: Optional[str] = None


class UsuarioResponse(UsuarioBase):
    id_usuario: UUID_STR
    id_persona: UUID_STR
    fecha_creacion: datetime
    persona: Optional[PersonaResponse] = None

    model_config = {"from_attributes": True}


class UsuarioConRolesResponse(UsuarioResponse):
    roles: List[UsuarioRolResponse] = []

    model_config = {"from_attributes": True}


# ════════════════════════════════════════════════════════════════
# AUTH
# ════════════════════════════════════════════════════════════════

class LoginRequest(BaseModel):
    username: str
    password: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    usuario: UsuarioConRolesResponse


# ════════════════════════════════════════════════════════════════
# PROVEEDOR
# ════════════════════════════════════════════════════════════════

class ProveedorBase(BaseModel):
    razon_social: str
    correo: Optional[str] = None
    telefono: Optional[str] = None
    direccion: Optional[str] = None
    estado: bool = True


class ProveedorNaturalCreate(ProveedorBase):
    tipo_proveedor: str = "natural"
    nombres: str
    apellidos: str
    cedula: Optional[str] = None


class ProveedorJuridicoCreate(ProveedorBase):
    tipo_proveedor: str = "juridico"
    ruc: Optional[str] = None
    nombre_comercial: Optional[str] = None
    representante_legal: Optional[str] = None


class ProveedorResponse(ProveedorBase):
    id_proveedor: UUID_STR
    tipo_proveedor: str
    fecha_registro: datetime

    model_config = {"from_attributes": True}


# ════════════════════════════════════════════════════════════════
# PRODUCTO ACUÍCOLA
# ════════════════════════════════════════════════════════════════

class ProductoBase(BaseModel):
    nombre: str
    descripcion: Optional[str] = None
    precio_unitario: float
    stock_actual: float = 0.0
    stock_minimo: float = 0.0
    unidad_medida: str = "kg"
    estado: bool = True
    id_proveedor: Optional[UUID_STR] = None


class BalanceadoCreate(ProductoBase):
    tipo_producto: str = "balanceado"
    tipo_especie: Optional[str] = None
    etapa_vida: Optional[str] = None


class InsumoCreate(ProductoBase):
    tipo_producto: str = "insumo"
    tipo_insumo: Optional[str] = None
    aplicacion: Optional[str] = None


class MedicamentoCreate(ProductoBase):
    tipo_producto: str = "medicamento"
    principio_activo: Optional[str] = None
    dosis_recomendada: Optional[str] = None
    registro_sanitario: Optional[str] = None


class EquipoCreate(ProductoBase):
    tipo_producto: str = "equipo"
    marca: Optional[str] = None
    modelo: Optional[str] = None
    garantia_meses: Optional[int] = None


class ProductoUpdate(BaseModel):
    nombre: Optional[str] = None
    descripcion: Optional[str] = None
    precio_unitario: Optional[float] = None
    stock_actual: Optional[float] = None
    stock_minimo: Optional[float] = None
    estado: Optional[bool] = None


class ProductoResponse(ProductoBase):
    id_producto: UUID_STR
    codigo_producto: str
    tipo_producto: str
    fecha_registro: datetime

    model_config = {"from_attributes": True}
