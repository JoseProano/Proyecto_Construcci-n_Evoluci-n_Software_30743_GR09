"""
AmazonFish – Tests para el módulo de Ventas y descuento de stock
"""
from models import ProductoAcuicola, Pedido, DetallePedido, Venta

def test_registrar_pago_exitoso_y_descuento_stock(client, db, auth_headers):
    # 1. Crear producto con stock
    prod = ProductoAcuicola(
        codigo_producto="PROD-BAL-2026-7777",
        nombre="Balanceado Engorde trucha",
        precio_unitario=20.0,
        stock_actual=10.0,
        unidad_medida="kg",
        tipo_producto="balanceado",
    )
    db.add(prod)
    db.flush()

    # 2. Crear pedido borrador de 3 unidades
    ped = Pedido(
        id_usuario="usuario-test-001",
        estado="borrador",
        subtotal=60.0,
        total=60.0,
    )
    db.add(ped)
    db.flush()

    det = DetallePedido(
        id_pedido=ped.id_pedido,
        id_producto=prod.id_producto,
        cantidad=3.0,
        precio_unitario=20.0,
        subtotal=60.0,
    )
    db.add(det)
    db.commit()

    # 3. Pagar el pedido
    payload = {
        "metodo_pago": "efectivo",
        "monto_pagado": 60.0
    }
    resp = client.post(f"/api/v1/ventas/pagar/{ped.id_pedido}", json=payload, headers=auth_headers)
    assert resp.status_code == 201
    
    # 4. Verificar que se creó la venta y el stock se redujo
    db.refresh(prod)
    db.refresh(ped)
    assert prod.stock_actual == 7.0  # 10.0 - 3.0
    assert ped.estado == "pagado"

def test_registrar_pago_insuficiente_stock_falla(client, db, auth_headers):
    # 1. Crear producto con stock insuficiente (solo 1 kg)
    prod = ProductoAcuicola(
        codigo_producto="PROD-BAL-2026-6666",
        nombre="Balanceado Engorde camarón",
        precio_unitario=20.0,
        stock_actual=1.0,
        unidad_medida="kg",
        tipo_producto="balanceado",
    )
    db.add(prod)
    db.flush()

    # 2. Crear pedido borrador de 3 unidades
    ped = Pedido(
        id_usuario="usuario-test-001",
        estado="borrador",
        subtotal=60.0,
        total=60.0,
    )
    db.add(ped)
    db.flush()

    det = DetallePedido(
        id_pedido=ped.id_pedido,
        id_producto=prod.id_producto,
        cantidad=3.0,
        precio_unitario=20.0,
        subtotal=60.0,
    )
    db.add(det)
    db.commit()

    # 3. Pagar el pedido (debería fallar con HTTP 400 por falta de stock)
    payload = {
        "metodo_pago": "transferencia",
        "monto_pagado": 60.0
    }
    resp = client.post(f"/api/v1/ventas/pagar/{ped.id_pedido}", json=payload, headers=auth_headers)
    assert resp.status_code == 400
    assert "Stock insuficiente" in resp.json()["detail"]

    # 4. Verificar que el stock se mantiene en 1.0 (no se modificó)
    db.refresh(prod)
    db.refresh(ped)
    assert prod.stock_actual == 1.0
    assert ped.estado == "borrador"
