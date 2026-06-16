"""
AmazonFish – Router: Productos Acuícolas
Usa el patrón Factory Method para crear cada tipo de producto
con código dinámico autogenerado.
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional

from database import get_db
from models import ProductoAcuicola
from schemas import (
    BalanceadoCreate, InsumoCreate, MedicamentoCreate, EquipoCreate,
    ProductoResponse, ProductoUpdate,
)
from services.producto_factory import get_factory
from security import get_current_user

router = APIRouter()


@router.get("/", response_model=List[ProductoResponse])
def listar_productos(
    tipo: Optional[str] = None,
    db: Session = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """Lista productos activos. Filtra opcionalmente por tipo."""
    q = db.query(ProductoAcuicola).filter(ProductoAcuicola.estado == True)
    if tipo:
        q = q.filter(ProductoAcuicola.tipo_producto == tipo)
    return q.all()


@router.post("/balanceado", response_model=ProductoResponse, status_code=status.HTTP_201_CREATED)
def crear_balanceado(
    datos: BalanceadoCreate,
    db: Session = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """Crea un balanceado usando el Factory Method. Código: PROD-BAL-YYYY-NNNN"""
    factory = get_factory("balanceado")
    producto = factory.crear(datos.model_dump(exclude={"tipo_producto"}), db)
    db.add(producto)
    db.commit()
    db.refresh(producto)
    return producto


@router.post("/insumo", response_model=ProductoResponse, status_code=status.HTTP_201_CREATED)
def crear_insumo(
    datos: InsumoCreate,
    db: Session = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """Crea un insumo acuícola. Código: PROD-INS-YYYY-NNNN"""
    factory = get_factory("insumo")
    producto = factory.crear(datos.model_dump(exclude={"tipo_producto"}), db)
    db.add(producto)
    db.commit()
    db.refresh(producto)
    return producto


@router.post("/medicamento", response_model=ProductoResponse, status_code=status.HTTP_201_CREATED)
def crear_medicamento(
    datos: MedicamentoCreate,
    db: Session = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """Crea un medicamento acuícola. Código: PROD-MED-YYYY-NNNN"""
    factory = get_factory("medicamento")
    producto = factory.crear(datos.model_dump(exclude={"tipo_producto"}), db)
    db.add(producto)
    db.commit()
    db.refresh(producto)
    return producto


@router.post("/equipo", response_model=ProductoResponse, status_code=status.HTTP_201_CREATED)
def crear_equipo(
    datos: EquipoCreate,
    db: Session = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """Crea un equipo acuícola. Código: PROD-EQU-YYYY-NNNN"""
    factory = get_factory("equipo")
    producto = factory.crear(datos.model_dump(exclude={"tipo_producto"}), db)
    db.add(producto)
    db.commit()
    db.refresh(producto)
    return producto


@router.get("/{id_producto}", response_model=ProductoResponse)
def obtener_producto(
    id_producto: str,
    db: Session = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    p = db.query(ProductoAcuicola).filter(ProductoAcuicola.id_producto == id_producto).first()
    if not p:
        raise HTTPException(status_code=404, detail="Producto no encontrado.")
    return p


@router.put("/{id_producto}", response_model=ProductoResponse)
def actualizar_producto(
    id_producto: str,
    datos: ProductoUpdate,
    db: Session = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    p = db.query(ProductoAcuicola).filter(ProductoAcuicola.id_producto == id_producto).first()
    if not p:
        raise HTTPException(status_code=404, detail="Producto no encontrado.")
    for campo, valor in datos.model_dump(exclude_none=True).items():
        setattr(p, campo, valor)
    db.commit()
    db.refresh(p)
    return p


@router.delete("/{id_producto}", status_code=status.HTTP_204_NO_CONTENT)
def eliminar_producto(
    id_producto: str,
    db: Session = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    p = db.query(ProductoAcuicola).filter(ProductoAcuicola.id_producto == id_producto).first()
    if not p:
        raise HTTPException(status_code=404, detail="Producto no encontrado.")
    p.estado = False
    db.commit()
