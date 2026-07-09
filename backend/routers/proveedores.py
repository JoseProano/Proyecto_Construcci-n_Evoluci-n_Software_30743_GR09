"""
AmazonFish – Router: Proveedores
Herencia: Proveedor → PersonaNatural | PersonaJuridica
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from database import get_db
from models import Proveedor, ProveedorPersonaNatural, ProveedorPersonaJuridica
from schemas import ProveedorNaturalCreate, ProveedorJuridicoCreate, ProveedorResponse, ProveedorUpdate
from security import get_current_user

router = APIRouter()


@router.get("/", response_model=List[ProveedorResponse])
def listar_proveedores(
    db: Session = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    return db.query(Proveedor).filter(Proveedor.estado == True).all()


@router.post("/natural", response_model=ProveedorResponse, status_code=status.HTTP_201_CREATED)
def crear_proveedor_natural(
    datos: ProveedorNaturalCreate,
    db: Session = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """Crea un proveedor persona natural (con cédula)."""
    p = ProveedorPersonaNatural(
        razon_social=datos.razon_social,
        correo=datos.correo,
        telefono=datos.telefono,
        direccion=datos.direccion,
        estado=datos.estado,
        tipo_proveedor="natural",
        nombres=datos.nombres,
        apellidos=datos.apellidos,
        cedula=datos.cedula,
    )
    db.add(p)
    db.commit()
    db.refresh(p)
    return p


@router.post("/juridico", response_model=ProveedorResponse, status_code=status.HTTP_201_CREATED)
def crear_proveedor_juridico(
    datos: ProveedorJuridicoCreate,
    db: Session = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """Crea un proveedor persona jurídica (empresa con RUC)."""
    p = ProveedorPersonaJuridica(
        razon_social=datos.razon_social,
        correo=datos.correo,
        telefono=datos.telefono,
        direccion=datos.direccion,
        estado=datos.estado,
        tipo_proveedor="juridico",
        ruc=datos.ruc,
        nombre_comercial=datos.nombre_comercial,
        representante_legal=datos.representante_legal,
    )
    db.add(p)
    db.commit()
    db.refresh(p)
    return p


@router.get("/{id_proveedor}", response_model=ProveedorResponse)
def obtener_proveedor(
    id_proveedor: str,
    db: Session = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    p = db.query(Proveedor).filter(Proveedor.id_proveedor == id_proveedor).first()
    if not p:
        raise HTTPException(status_code=404, detail="Proveedor no encontrado.")
    return p


@router.delete("/{id_proveedor}", status_code=status.HTTP_204_NO_CONTENT)
def eliminar_proveedor(
    id_proveedor: str,
    db: Session = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    p = db.query(Proveedor).filter(Proveedor.id_proveedor == id_proveedor).first()
    if not p:
        raise HTTPException(status_code=404, detail="Proveedor no encontrado.")
    p.estado = False
    db.commit()


@router.put("/{id_proveedor}", response_model=ProveedorResponse)
def actualizar_proveedor(
    id_proveedor: str,
    datos: ProveedorUpdate,
    db: Session = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    p = db.query(Proveedor).filter(Proveedor.id_proveedor == id_proveedor).first()
    if not p:
        raise HTTPException(status_code=404, detail="Proveedor no encontrado.")
    
    # Actualizar campos comunes
    for campo in ["razon_social", "correo", "telefono", "direccion", "estado"]:
        valor = getattr(datos, campo, None)
        if valor is not None:
            setattr(p, campo, valor)

    # Actualizar campos específicos si es subclase
    if p.tipo_proveedor == "natural" and isinstance(p, ProveedorPersonaNatural):
        for campo in ["nombres", "apellidos", "cedula"]:
            valor = getattr(datos, campo, None)
            if valor is not None:
                setattr(p, campo, valor)
    elif p.tipo_proveedor == "juridico" and isinstance(p, ProveedorPersonaJuridica):
        for campo in ["ruc", "nombre_comercial", "representante_legal"]:
            valor = getattr(datos, campo, None)
            if valor is not None:
                setattr(p, campo, valor)

    db.commit()
    db.refresh(p)
    return p
