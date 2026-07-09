"""
AmazonFish – Tests para el módulo de Proveedores (Natural y Jurídico)
Verifica CRUD completo, endpoints de creación polimórficos, listados y actualización.
"""
import pytest
from models import Proveedor, ProveedorPersonaNatural, ProveedorPersonaJuridica

def test_crear_proveedor_natural_exitoso(client, db, auth_headers):
    payload = {
        "razon_social": "Proveedor Natural S.A.",
        "correo": "natural@test.com",
        "telefono": "0999999999",
        "direccion": "Quito",
        "estado": True,
        "tipo_proveedor": "natural",
        "nombres": "Juan José",
        "apellidos": "Pazmiño Mora",
        "cedula": "1712345678"
    }
    resp = client.post("/api/v1/proveedores/natural", json=payload, headers=auth_headers)
    assert resp.status_code == 201
    data = resp.json()
    assert data["razon_social"] == "Proveedor Natural S.A."
    assert data["tipo_proveedor"] == "natural"
    assert data["cedula"] == "1712345678"
    assert data["nombres"] == "Juan José"

def test_crear_proveedor_juridico_exitoso(client, db, auth_headers):
    payload = {
        "razon_social": "Corporacion Alimentos Cía. Ltda.",
        "correo": "corp@test.com",
        "telefono": "022999999",
        "direccion": "Guayaquil",
        "estado": True,
        "tipo_proveedor": "juridico",
        "ruc": "1791234567001",
        "nombre_comercial": "Alimentos del Mar",
        "representante_legal": "Ing. Carlos Mendoza"
    }
    resp = client.post("/api/v1/proveedores/juridico", json=payload, headers=auth_headers)
    assert resp.status_code == 201
    data = resp.json()
    assert data["razon_social"] == "Corporacion Alimentos Cía. Ltda."
    assert data["tipo_proveedor"] == "juridico"
    assert data["ruc"] == "1791234567001"
    assert data["nombre_comercial"] == "Alimentos del Mar"

def test_listar_proveedores(client, db, auth_headers):
    resp = client.get("/api/v1/proveedores/", headers=auth_headers)
    assert resp.status_code == 200
    assert isinstance(resp.json(), list)

def test_obtener_proveedor_especifico(client, db, auth_headers):
    # Crear uno
    p = ProveedorPersonaNatural(
        razon_social="Prov Específico",
        tipo_proveedor="natural",
        nombres="Edu",
        apellidos="Rosas",
        cedula="1812345678"
    )
    db.add(p)
    db.commit()

    resp = client.get(f"/api/v1/proveedores/{p.id_proveedor}", headers=auth_headers)
    assert resp.status_code == 200
    assert resp.json()["id_proveedor"] == p.id_proveedor

def test_obtener_proveedor_no_encontrado(client, auth_headers):
    resp = client.get("/api/v1/proveedores/00000000-0000-0000-0000-000000000000", headers=auth_headers)
    assert resp.status_code == 404

def test_actualizar_proveedor_natural(client, db, auth_headers):
    p = ProveedorPersonaNatural(
        razon_social="Prov A Actualizar",
        tipo_proveedor="natural",
        nombres="Luis",
        apellidos="Gomez",
        cedula="1234567890"
    )
    db.add(p)
    db.commit()

    payload = {
        "razon_social": "Prov Actualizado S.A.",
        "correo": "nuevo@correo.com",
        "nombres": "Luis Alberto",
        "cedula": "0987654321"
    }
    resp = client.put(f"/api/v1/proveedores/{p.id_proveedor}", json=payload, headers=auth_headers)
    assert resp.status_code == 200
    data = resp.json()
    assert data["razon_social"] == "Prov Actualizado S.A."
    assert data["correo"] == "nuevo@correo.com"
    assert data["nombres"] == "Luis Alberto"
    assert data["cedula"] == "0987654321"

def test_actualizar_proveedor_juridico(client, db, auth_headers):
    p = ProveedorPersonaJuridica(
        razon_social="Empresa A Actualizar",
        tipo_proveedor="juridico",
        ruc="1790000000001",
        nombre_comercial="Comercial Uno",
        representante_legal="Gerente Uno"
    )
    db.add(p)
    db.commit()

    payload = {
        "razon_social": "Empresa Actualizada",
        "ruc": "1799999999001",
        "nombre_comercial": "Comercial Dos"
    }
    resp = client.put(f"/api/v1/proveedores/{p.id_proveedor}", json=payload, headers=auth_headers)
    assert resp.status_code == 200
    data = resp.json()
    assert data["razon_social"] == "Empresa Actualizada"
    assert data["ruc"] == "1799999999001"
    assert data["nombre_comercial"] == "Comercial Dos"

def test_actualizar_proveedor_no_encontrado(client, auth_headers):
    payload = {
        "razon_social": "No Existe"
    }
    resp = client.put("/api/v1/proveedores/00000000-0000-0000-0000-000000000000", json=payload, headers=auth_headers)
    assert resp.status_code == 404

def test_eliminar_proveedor_exitoso(client, db, auth_headers):
    p = ProveedorPersonaNatural(
        razon_social="Prov A Eliminar",
        tipo_proveedor="natural",
        nombres="Eliminar",
        apellidos="Test",
        cedula="1111111110"
    )
    db.add(p)
    db.commit()

    resp = client.delete(f"/api/v1/proveedores/{p.id_proveedor}", headers=auth_headers)
    assert resp.status_code == 204

    # Verificar que cambio a inactivo
    db.refresh(p)
    assert p.estado is False
