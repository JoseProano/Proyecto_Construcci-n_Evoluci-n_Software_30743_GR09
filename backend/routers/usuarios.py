"""
AmazonFish – Router: Usuarios
Creación con hash de contraseña, CRUD, vinculación Persona 1:1 Usuario.
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from database import get_db
from models import Usuario, Persona
from schemas import UsuarioCreate, UsuarioUpdate, UsuarioResponse, UsuarioConRolesResponse
from security import get_password_hash, get_current_user

router = APIRouter()


@router.get("/", response_model=List[UsuarioConRolesResponse])
def listar_usuarios(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """Lista todos los usuarios activos con sus roles asignados."""
    return (
        db.query(Usuario)
        .filter(Usuario.estado == True)
        .offset(skip)
        .limit(limit)
        .all()
    )


@router.post("/", response_model=UsuarioResponse, status_code=status.HTTP_201_CREATED)
def crear_usuario(
    datos: UsuarioCreate,
    db: Session = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """
    Crea un usuario vinculado a una Persona existente.
    La contraseña se almacena como hash bcrypt (NUNCA en texto plano).
    """
    # Persona debe existir
    persona = db.query(Persona).filter(Persona.id_persona == datos.id_persona).first()
    if not persona:
        raise HTTPException(status_code=404, detail="Persona no encontrada.")

    # Una persona solo puede tener un usuario
    if db.query(Usuario).filter(Usuario.id_persona == datos.id_persona).first():
        raise HTTPException(status_code=400, detail="Esta persona ya tiene un usuario asignado.")

    # Username único
    if db.query(Usuario).filter(Usuario.username == datos.username).first():
        raise HTTPException(status_code=400, detail="El username ya está en uso.")

    nuevo = Usuario(
        id_persona=datos.id_persona,
        username=datos.username,
        password_hash=get_password_hash(datos.password),  # bcrypt hash
        estado=datos.estado,
    )
    db.add(nuevo)
    db.commit()
    db.refresh(nuevo)
    return nuevo


@router.get("/{id_usuario}", response_model=UsuarioConRolesResponse)
def obtener_usuario(
    id_usuario: str,
    db: Session = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    u = db.query(Usuario).filter(Usuario.id_usuario == id_usuario).first()
    if not u:
        raise HTTPException(status_code=404, detail="Usuario no encontrado.")
    return u


@router.put("/{id_usuario}", response_model=UsuarioResponse)
def actualizar_usuario(
    id_usuario: str,
    datos: UsuarioUpdate,
    db: Session = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    u = db.query(Usuario).filter(Usuario.id_usuario == id_usuario).first()
    if not u:
        raise HTTPException(status_code=404, detail="Usuario no encontrado.")

    update = datos.model_dump(exclude_none=True)
    if "password" in update:
        update["password_hash"] = get_password_hash(update.pop("password"))
    for campo, valor in update.items():
        setattr(u, campo, valor)

    db.commit()
    db.refresh(u)
    return u


@router.delete("/{id_usuario}", status_code=status.HTTP_204_NO_CONTENT)
def eliminar_usuario(
    id_usuario: str,
    db: Session = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """Eliminación lógica del usuario."""
    u = db.query(Usuario).filter(Usuario.id_usuario == id_usuario).first()
    if not u:
        raise HTTPException(status_code=404, detail="Usuario no encontrado.")
    u.estado = False
    db.commit()
