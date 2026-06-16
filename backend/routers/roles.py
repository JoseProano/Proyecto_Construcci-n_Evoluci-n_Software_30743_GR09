"""
AmazonFish – Router: Roles
CRUD de roles + asignación/remoción de roles a usuarios.
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from database import get_db
from models import Rol, UsuarioRol, Usuario
from schemas import RolCreate, RolUpdate, RolResponse, AsignarRolSchema, UsuarioRolResponse
from security import get_current_user

router = APIRouter()


@router.get("/", response_model=List[RolResponse])
def listar_roles(
    db: Session = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """Lista todos los roles activos del sistema."""
    return db.query(Rol).filter(Rol.estado == True).all()


@router.post("/", response_model=RolResponse, status_code=status.HTTP_201_CREATED)
def crear_rol(
    datos: RolCreate,
    db: Session = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """Crea un nuevo rol. El nombre debe ser único."""
    if db.query(Rol).filter(Rol.nombre == datos.nombre).first():
        raise HTTPException(status_code=400, detail="Ya existe un rol con ese nombre.")
    rol = Rol(**datos.model_dump())
    db.add(rol)
    db.commit()
    db.refresh(rol)
    return rol


@router.get("/{id_rol}", response_model=RolResponse)
def obtener_rol(
    id_rol: str,
    db: Session = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    r = db.query(Rol).filter(Rol.id_rol == id_rol).first()
    if not r:
        raise HTTPException(status_code=404, detail="Rol no encontrado.")
    return r


@router.put("/{id_rol}", response_model=RolResponse)
def actualizar_rol(
    id_rol: str,
    datos: RolUpdate,
    db: Session = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    r = db.query(Rol).filter(Rol.id_rol == id_rol).first()
    if not r:
        raise HTTPException(status_code=404, detail="Rol no encontrado.")
    for campo, valor in datos.model_dump(exclude_none=True).items():
        setattr(r, campo, valor)
    db.commit()
    db.refresh(r)
    return r


@router.delete("/{id_rol}", status_code=status.HTTP_204_NO_CONTENT)
def eliminar_rol(
    id_rol: str,
    db: Session = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    r = db.query(Rol).filter(Rol.id_rol == id_rol).first()
    if not r:
        raise HTTPException(status_code=404, detail="Rol no encontrado.")
    r.estado = False
    db.commit()


@router.post("/asignar", response_model=UsuarioRolResponse, status_code=status.HTTP_201_CREATED)
def asignar_rol(
    datos: AsignarRolSchema,
    db: Session = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """Asigna un rol a un usuario (relación N:M vía tabla UsuarioRol)."""
    if not db.query(Usuario).filter(Usuario.id_usuario == datos.id_usuario).first():
        raise HTTPException(status_code=404, detail="Usuario no encontrado.")
    if not db.query(Rol).filter(Rol.id_rol == datos.id_rol).first():
        raise HTTPException(status_code=404, detail="Rol no encontrado.")

    existente = db.query(UsuarioRol).filter(
        UsuarioRol.id_usuario == datos.id_usuario,
        UsuarioRol.id_rol == datos.id_rol,
        UsuarioRol.estado == True,
    ).first()
    if existente:
        raise HTTPException(status_code=400, detail="El rol ya está asignado a este usuario.")

    asignacion = UsuarioRol(id_usuario=datos.id_usuario, id_rol=datos.id_rol)
    db.add(asignacion)
    db.commit()
    db.refresh(asignacion)
    return asignacion


@router.delete("/remover/{id_usuario_rol}", status_code=status.HTTP_204_NO_CONTENT)
def remover_rol(
    id_usuario_rol: str,
    db: Session = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """Remueve la asignación de un rol a un usuario (eliminación lógica)."""
    a = db.query(UsuarioRol).filter(UsuarioRol.id_usuario_rol == id_usuario_rol).first()
    if not a:
        raise HTTPException(status_code=404, detail="Asignación no encontrada.")
    a.estado = False
    db.commit()
