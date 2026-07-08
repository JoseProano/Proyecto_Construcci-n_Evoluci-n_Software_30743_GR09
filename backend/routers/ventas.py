"""
AmazonFish – Router: Ventas
Registro de ventas, cobros y descuento atómico de inventario (Kardex).
Cumple con RNF-06 (transacción atómica).
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from database import get_db
from models import Pedido, Venta, ProductoAcuicola
from schemas import VentaCreate, VentaResponse
from security import get_current_user, require_role

router = APIRouter()


@router.post("/pagar/{id_pedido}", response_model=VentaResponse, status_code=status.HTTP_201_CREATED)
def registrar_pago(
    id_pedido: str,
    datos: VentaCreate,
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_role("vendedor")),
):
    """
    Registra el pago de un pedido y crea la venta.
    Realiza el descuento de stock de manera atómica (RNF-06).
    Si un producto no tiene suficiente stock, se hace rollback automático de toda la operación.
    """
    # Buscar el pedido
    pedido = db.query(Pedido).filter(Pedido.id_pedido == id_pedido).first()
    if not pedido:
        raise HTTPException(status_code=404, detail="Pedido no encontrado.")

    if pedido.estado != "borrador":
        raise HTTPException(
            status_code=400,
            detail=f"El pedido ya está en estado '{pedido.estado}'. Solo se pueden pagar borradores.",
        )

    # Validar stock y descontar en una sola transacción
    for detalle in pedido.detalles:
        producto = db.query(ProductoAcuicola).filter(
            ProductoAcuicola.id_producto == detalle.id_producto
        ).with_for_update().first()  # Bloquea la fila para evitar condiciones de carrera

        if not producto:
            raise HTTPException(
                status_code=404,
                detail=f"Producto '{detalle.id_producto}' no encontrado.",
            )

        if not producto.estado:
            raise HTTPException(
                status_code=400,
                detail=f"El producto '{producto.nombre}' está inactivo y no se puede vender.",
            )

        # Verificar existencias
        if float(producto.stock_actual) < float(detalle.cantidad):
            raise HTTPException(
                status_code=400,
                detail=(
                    f"Stock insuficiente para '{producto.nombre}'. "
                    f"Disponible: {producto.stock_actual} {producto.unidad_medida}, "
                    f"Requerido: {detalle.cantidad} {producto.unidad_medida}."
                ),
            )

        # Descontar stock
        producto.stock_actual = float(producto.stock_actual) - float(detalle.cantidad)

    # Crear la venta
    nueva_venta = Venta(
        id_pedido=pedido.id_pedido,
        metodo_pago=datos.metodo_pago,
        monto_pagado=datos.monto_pagado,
    )
    db.add(nueva_venta)

    # Cambiar estado del pedido
    pedido.estado = "pagado"

    try:
        db.commit()
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=500,
            detail=f"Error al procesar el cobro en la base de datos: {str(e)}",
        )

    db.refresh(nueva_venta)
    return nueva_venta


@router.get("/", response_model=List[VentaResponse])
def listar_ventas(
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_role("vendedor")),
):
    """Lista todas las ventas registradas (vendedores y admins)."""
    return db.query(Venta).order_by(Venta.fecha_venta.desc()).all()


@router.get("/{id_venta}", response_model=VentaResponse)
def obtener_venta(
    id_venta: str,
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_role("vendedor")),
):
    """Obtiene el detalle de una venta específica."""
    venta = db.query(Venta).filter(Venta.id_venta == id_venta).first()
    if not venta:
        raise HTTPException(status_code=404, detail="Venta no encontrada.")
    return venta
