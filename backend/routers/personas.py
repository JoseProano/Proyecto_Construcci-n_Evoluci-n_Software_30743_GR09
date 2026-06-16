"""
AmazonFish – Router: Personas
CRUD completo. Eliminación lógica (estado=False).
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from database import get_db
from models import Persona
from schemas import PersonaCreate, PersonaUpdate, PersonaResponse
from security import get_current_user

router = APIRouter()


@router.get("/", response_model=List[PersonaResponse])
def listar_personas(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """Lista todas las personas activas del sistema."""
    return (
        db.query(Persona)
        .filter(Persona.estado == True)
        .offset(skip)
        .limit(limit)
        .all()
    )


@router.post("/", response_model=PersonaResponse, status_code=status.HTTP_201_CREATED)
def crear_persona(
    datos: PersonaCreate,
    db: Session = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """Crea una nueva persona. Verifica duplicados de identificación y correo."""
    existing = db.query(Persona).filter(
        (Persona.identificacion == datos.identificacion)
        | (Persona.correo == datos.correo)
    ).first()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Ya existe una persona con esa identificación o correo electrónico.",
        )
    nueva = Persona(**datos.model_dump())
    db.add(nueva)
    db.commit()
    db.refresh(nueva)
    return nueva


@router.get("/{id_persona}", response_model=PersonaResponse)
def obtener_persona(
    id_persona: str,
    db: Session = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """Obtiene una persona activa por su UUID."""
    p = db.query(Persona).filter(
        Persona.id_persona == id_persona,
        Persona.estado == True,
    ).first()
    if not p:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Persona no encontrada.")
    return p


@router.put("/{id_persona}", response_model=PersonaResponse)
def actualizar_persona(
    id_persona: str,
    datos: PersonaUpdate,
    db: Session = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """Actualiza los datos de una persona existente."""
    p = db.query(Persona).filter(Persona.id_persona == id_persona).first()
    if not p:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Persona no encontrada.")
    for campo, valor in datos.model_dump(exclude_none=True).items():
        setattr(p, campo, valor)
    db.commit()
    db.refresh(p)
    return p


@router.delete("/{id_persona}", status_code=status.HTTP_204_NO_CONTENT)
def eliminar_persona(
    id_persona: str,
    db: Session = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """Eliminación lógica: cambia estado a False (no borra el registro)."""
    p = db.query(Persona).filter(Persona.id_persona == id_persona).first()
    if not p:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Persona no encontrada.")
    p.estado = False
    db.commit()
