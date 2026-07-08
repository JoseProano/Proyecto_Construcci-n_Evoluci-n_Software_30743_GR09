"""
AmazonFish – Tests para el módulo de Pedidos
"""
from models import ProductoAcuicola, Pedido

def test_crear_pedido_exitoso(client, db, auth_headers):
    # 1. Crear un producto de prueba en la DB
    prod = ProductoAcuicola(
        codigo_producto="PROD-BAL-2026-9999",
        nombre="Balanceado Iniciación Premium",
        precio_unitario=15.50,
        stock_actual=100.0,
        unidad_medida="kg",
        tipo_producto="balanceado",
    )
    db.add(prod)
    db.commit()

    # 2. Hacer request de creación de pedido
    payload = {
        "descuento": 5.0,
        "detalles": [
            {"id_producto": prod.id_producto, "cantidad": 2}
        ]
    }
    resp = client.post("/api/v1/pedidos/", json=payload, headers=auth_headers)
    assert resp.status_code == 201
    data = resp.json()
    assert data["estado"] == "borrador"
    assert data["subtotal"] == 31.0  # 15.5 * 2
    assert data["descuento"] == 5.0
    assert data["total"] == 26.0     # 31.0 - 5.0
    assert len(data["detalles"]) == 1

def test_listar_pedidos(client, db, auth_headers):
    # 1. Crear un pedido directamente
    ped = Pedido(
        id_usuario="usuario-test-001",
        estado="borrador",
        subtotal=50.0,
        total=50.0,
    )
    db.add(ped)
    db.commit()

    resp = client.get("/api/v1/pedidos/", headers=auth_headers)
    assert resp.status_code == 200
    data = resp.json()
    assert len(data) >= 1
    assert data[0]["id_pedido"] == ped.id_pedido

def test_actualizar_pedido_borrador(client, db, auth_headers):
    # 1. Crear producto y pedido
    prod = ProductoAcuicola(
        codigo_producto="PROD-BAL-2026-8888",
        nombre="Balanceado Crecimiento",
        precio_unitario=10.0,
        stock_actual=50.0,
        unidad_medida="kg",
        tipo_producto="balanceado",
    )
    db.add(prod)
    db.commit()

    ped = Pedido(
        id_usuario="usuario-test-001",
        estado="borrador",
        subtotal=10.0,
        total=10.0,
    )
    db.add(ped)
    db.commit()

    # 2. Actualizar el pedido
    payload = {
        "descuento": 2.0,
        "detalles": [
            {"id_producto": prod.id_producto, "cantidad": 4}
        ]
    }
    resp = client.put(f"/api/v1/pedidos/{ped.id_pedido}", json=payload, headers=auth_headers)
    assert resp.status_code == 200
    data = resp.json()
    assert data["subtotal"] == 40.0
    assert data["total"] == 38.0

def test_cancelar_pedido_borrador(client, db, auth_headers):
    ped = Pedido(
        id_usuario="usuario-test-001",
        estado="borrador",
        subtotal=10.0,
        total=10.0,
    )
    db.add(ped)
    db.commit()

    resp = client.delete(f"/api/v1/pedidos/{ped.id_pedido}", headers=auth_headers)
    assert resp.status_code == 204

    # Verificar que cambió a cancelado
    db.refresh(ped)
    assert ped.estado == "cancelado"

def test_crear_pedido_sin_detalles(client, auth_headers):
    payload = {
        "descuento": 0.0,
        "detalles": []
    }
    resp = client.post("/api/v1/pedidos/", json=payload, headers=auth_headers)
    assert resp.status_code == 400
    assert "al menos un producto" in resp.json()["detail"]

def test_crear_pedido_cantidad_invalida(client, db, auth_headers):
    prod = ProductoAcuicola(
        codigo_producto="PROD-BAL-2026-1111",
        nombre="Test Prod",
        precio_unitario=5.0,
        stock_actual=10.0,
        unidad_medida="kg",
        tipo_producto="balanceado",
    )
    db.add(prod)
    db.commit()

    payload = {
        "descuento": 0.0,
        "detalles": [
            {"id_producto": prod.id_producto, "cantidad": -2.0}
        ]
    }
    resp = client.post("/api/v1/pedidos/", json=payload, headers=auth_headers)
    assert resp.status_code == 400
    assert "mayor a cero" in resp.json()["detail"]

def test_crear_pedido_producto_inexistente(client, auth_headers):
    payload = {
        "descuento": 0.0,
        "detalles": [
            {"id_producto": "00000000-0000-0000-0000-000000000000", "cantidad": 2.0}
        ]
    }
    resp = client.post("/api/v1/pedidos/", json=payload, headers=auth_headers)
    assert resp.status_code == 404
    assert "no encontrado" in resp.json()["detail"]

def test_actualizar_pedido_no_encontrado(client, auth_headers):
    payload = {
        "descuento": 0.0,
        "detalles": []
    }
    resp = client.put("/api/v1/pedidos/00000000-0000-0000-0000-000000000000", json=payload, headers=auth_headers)
    assert resp.status_code == 404

def test_actualizar_pedido_no_borrador(client, db, auth_headers):
    ped = Pedido(
        id_usuario="usuario-test-001",
        estado="pagado",
        subtotal=10.0,
        total=10.0,
    )
    db.add(ped)
    db.commit()

    payload = {
        "descuento": 0.0,
        "detalles": []
    }
    resp = client.put(f"/api/v1/pedidos/{ped.id_pedido}", json=payload, headers=auth_headers)
    assert resp.status_code == 400
    assert "estado 'borrador'" in resp.json()["detail"]

def test_cancelar_pedido_no_encontrado(client, auth_headers):
    resp = client.delete("/api/v1/pedidos/00000000-0000-0000-0000-000000000000", headers=auth_headers)
    assert resp.status_code == 404

def test_cancelar_pedido_no_borrador(client, db, auth_headers):
    ped = Pedido(
        id_usuario="usuario-test-001",
        estado="pagado",
        subtotal=10.0,
        total=10.0,
    )
    db.add(ped)
    db.commit()

    resp = client.delete(f"/api/v1/pedidos/{ped.id_pedido}", headers=auth_headers)
    assert resp.status_code == 400
    assert "estado 'borrador'" in resp.json()["detail"]

