"""
AmazonFish – Router: Pedidos
CRUD de pedidos. Permite calcular subtotales, totales y descuentos automáticamente.
Aplica visibilidad y restricciones según el rol del usuario.
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional

from database import get_db
from models import Pedido, DetallePedido, ProductoAcuicola, Usuario
from schemas import PedidoCreate, PedidoResponse
from security import get_current_user

router = APIRouter()


@router.post("/", response_model=PedidoResponse, status_code=status.HTTP_201_CREATED)
def crear_pedido(
    datos: PedidoCreate,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    """
    Crea un pedido en estado 'borrador'.
    Calcula de manera automática los subtotales y el total consultando los precios en la DB.
    """
    # Si no se especifica usuario, se asocia al usuario actual
    id_usuario = datos.id_usuario or current_user.get("sub")
    usuario = db.query(Usuario).filter(Usuario.id_usuario == id_usuario).first()
    if not usuario:
        raise HTTPException(status_code=404, detail="Usuario no encontrado.")

    if not datos.detalles:
        raise HTTPException(status_code=400, detail="El pedido debe contener al menos un producto.")

    nuevo_pedido = Pedido(
        id_usuario=id_usuario,
        estado="borrador",
        subtotal=0.0,
        descuento=datos.descuento,
        total=0.0,
    )
    db.add(nuevo_pedido)
    db.flush()

    subtotal_acumulado = 0.0

    for item in datos.detalles:
        producto = db.query(ProductoAcuicola).filter(
            ProductoAcuicola.id_producto == item.id_producto,
            ProductoAcuicola.estado == True,
        ).first()

        if not producto:
            raise HTTPException(
                status_code=404,
                detail=f"Producto con ID {item.id_producto} no encontrado o inactivo.",
            )

        if item.cantidad <= 0:
            raise HTTPException(status_code=400, detail="La cantidad debe ser mayor a cero.")

        item_subtotal = float(producto.precio_unitario) * item.cantidad
        subtotal_acumulado += item_subtotal

        detalle = DetallePedido(
            id_pedido=nuevo_pedido.id_pedido,
            id_producto=item.id_producto,
            cantidad=item.cantidad,
            precio_unitario=producto.precio_unitario,
            subtotal=item_subtotal,
        )
        db.add(detalle)

    nuevo_pedido.subtotal = subtotal_acumulado
    nuevo_pedido.total = max(0.0, subtotal_acumulado - datos.descuento)

    db.commit()
    db.refresh(nuevo_pedido)
    return nuevo_pedido


@router.get("/", response_model=List[PedidoResponse])
def listar_pedidos(
    estado: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    """
    Lista los pedidos.
    Los socios (clientes) solo pueden ver sus propios pedidos.
    Admins y vendedores pueden ver todo.
    """
    roles = current_user.get("roles", [])
    user_id = current_user.get("sub")

    q = db.query(Pedido)

    # Filtrar por rol
    if "administrador" not in roles and "vendedor" not in roles:
        # Es socio, solo ve los suyos
        q = q.filter(Pedido.id_usuario == user_id)

    if estado:
        q = q.filter(Pedido.estado == estado)

    return q.order_by(Pedido.fecha_pedido.desc()).all()


@router.get("/{id_pedido}", response_model=PedidoResponse)
def obtener_pedido(
    id_pedido: str,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    """Obtiene los detalles de un pedido específico."""
    pedido = db.query(Pedido).filter(Pedido.id_pedido == id_pedido).first()
    if not pedido:
        raise HTTPException(status_code=404, detail="Pedido no encontrado.")

    # Permisos
    roles = current_user.get("roles", [])
    if "administrador" not in roles and "vendedor" not in roles:
        if pedido.id_usuario != current_user.get("sub"):
            raise HTTPException(status_code=403, detail="Acceso denegado a este pedido.")

    return pedido


@router.put("/{id_pedido}", response_model=PedidoResponse)
def actualizar_pedido(
    id_pedido: str,
    datos: PedidoCreate,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    """
    Actualiza un pedido existente.
    Solo se puede modificar si está en estado 'borrador'.
    """
    pedido = db.query(Pedido).filter(Pedido.id_pedido == id_pedido).first()
    if not pedido:
        raise HTTPException(status_code=404, detail="Pedido no encontrado.")

    # Permisos
    roles = current_user.get("roles", [])
    if "administrador" not in roles and "vendedor" not in roles:
        if pedido.id_usuario != current_user.get("sub"):
            raise HTTPException(status_code=403, detail="Acceso denegado a este pedido.")

    if pedido.estado != "borrador":
        raise HTTPException(
            status_code=400,
            detail="Solo se pueden modificar pedidos en estado 'borrador'.",
        )

    # Eliminar detalles viejos
    db.query(DetallePedido).filter(DetallePedido.id_pedido == id_pedido).delete()

    subtotal_acumulado = 0.0
    for item in datos.detalles:
        producto = db.query(ProductoAcuicola).filter(
            ProductoAcuicola.id_producto == item.id_producto,
            ProductoAcuicola.estado == True,
        ).first()

        if not producto:
            raise HTTPException(
                status_code=404,
                detail=f"Producto con ID {item.id_producto} no encontrado o inactivo.",
            )

        item_subtotal = float(producto.precio_unitario) * item.cantidad
        subtotal_acumulado += item_subtotal

        detalle = DetallePedido(
            id_pedido=pedido.id_pedido,
            id_producto=item.id_producto,
            cantidad=item.cantidad,
            precio_unitario=producto.precio_unitario,
            subtotal=item_subtotal,
        )
        db.add(detalle)

    pedido.subtotal = subtotal_acumulado
    pedido.descuento = datos.descuento
    pedido.total = max(0.0, subtotal_acumulado - datos.descuento)

    db.commit()
    db.refresh(pedido)
    return pedido


@router.delete("/{id_pedido}", status_code=status.HTTP_204_NO_CONTENT)
def cancelar_pedido(
    id_pedido: str,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    """
    Cancela un pedido (cambia su estado a 'cancelado').
    Solo se puede cancelar si está en estado 'borrador'.
    """
    pedido = db.query(Pedido).filter(Pedido.id_pedido == id_pedido).first()
    if not pedido:
        raise HTTPException(status_code=404, detail="Pedido no encontrado.")

    # Permisos
    roles = current_user.get("roles", [])
    if "administrador" not in roles and "vendedor" not in roles:
        if pedido.id_usuario != current_user.get("sub"):
            raise HTTPException(status_code=403, detail="Acceso denegado a este pedido.")

    if pedido.estado != "borrador":
        raise HTTPException(
            status_code=400,
            detail="Solo se pueden cancelar pedidos en estado 'borrador'.",
        )

    pedido.estado = "cancelado"
    db.commit()
