"""
AmazonFish – Tests para endpoints públicos de Auth (Registro y Recuperación de Clave)
Asegura la cobertura de las nuevas líneas en routers/auth.py
"""
import pytest
from models import Persona, Usuario, Rol

def test_registro_publico_exitoso(client, db):
    payload = {
        "nombres": "Cliente",
        "apellidos": "Nuevo",
        "identificacion": "1234567890",
        "correo": "cliente.nuevo@test.com",
        "telefono": "0999999999",
        "username": "clientenuevo",
        "password": "password123"
    }
    resp = client.post("/api/v1/auth/register", json=payload)
    assert resp.status_code == 201
    data = resp.json()
    assert "Registro completado con éxito" in data["message"]
    
    # Verificar en DB
    usuario = db.query(Usuario).filter(Usuario.username == "clientenuevo").first();
    assert usuario is not None
    assert usuario.persona.identificacion == "1234567890"

def test_registro_publico_duplicado_persona(client, db):
    # Crear persona de prueba existente
    p = Persona(
        nombres="Existing",
        apellidos="Person",
        identificacion="1111111111",
        correo="existing@test.com"
    )
    db.add(p)
    db.commit()

    payload = {
        "nombres": "Otro",
        "apellidos": "Nombre",
        "identificacion": "1111111111", # Duplicado
        "correo": "otro@test.com",
        "username": "otrouser",
        "password": "password123"
    }
    resp = client.post("/api/v1/auth/register", json=payload)
    assert resp.status_code == 400
    assert "Ya existe una persona registrada" in resp.json()["detail"]

def test_registro_publico_duplicado_username(client, db):
    # Crear usuario de prueba existente
    p = Persona(
        nombres="User",
        apellidos="Existing",
        identificacion="2222222222",
        correo="user.existing@test.com"
    )
    db.add(p)
    db.flush()
    u = Usuario(
        id_persona=p.id_persona,
        username="existing_user_name",
        password_hash="hash"
    )
    db.add(u)
    db.commit()

    payload = {
        "nombres": "Otro",
        "apellidos": "Nombre",
        "identificacion": "3333333333",
        "correo": "otro@test.com",
        "username": "existing_user_name", # Duplicado
        "password": "password123"
    }
    resp = client.post("/api/v1/auth/register", json=payload)
    assert resp.status_code == 400
    assert "nombre de usuario ya está en uso" in resp.json()["detail"]

def test_recuperacion_contrasena_exitosa(client, db):
    # Crear usuario y persona
    p = Persona(
        nombres="Rec",
        apellidos="User",
        identificacion="8888888888",
        correo="rec@test.com"
    )
    db.add(p)
    db.flush()
    u = Usuario(
        id_persona=p.id_persona,
        username="rec_user",
        password_hash="old_hash"
    )
    db.add(u)
    db.commit()

    payload = {
        "username": "rec_user",
        "identificacion": "8888888888",
        "correo": "rec@test.com",
        "new_password": "newpassword123"
    }
    resp = client.post("/api/v1/auth/recover-password", json=payload)
    assert resp.status_code == 200
    assert "Contraseña restablecida correctamente" in resp.json()["message"]

def test_recuperacion_contrasena_usuario_no_encontrado(client, db):
    payload = {
        "username": "no_existe",
        "identificacion": "8888888888",
        "correo": "rec@test.com",
        "new_password": "newpassword123"
    }
    resp = client.post("/api/v1/auth/recover-password", json=payload)
    assert resp.status_code == 404
    assert "Nombre de usuario no encontrado" in resp.json()["detail"]

def test_recuperacion_contrasena_datos_mismatch(client, db):
    # Crear usuario y persona
    p = Persona(
        nombres="Rec2",
        apellidos="User",
        identificacion="7777777777",
        correo="rec2@test.com"
    )
    db.add(p)
    db.flush()
    u = Usuario(
        id_persona=p.id_persona,
        username="rec_user2",
        password_hash="old_hash"
    )
    db.add(u)
    db.commit()

    payload = {
        "username": "rec_user2",
        "identificacion": "7777777777",
        "correo": "incorrecto@test.com", # Correo incorrecto
        "new_password": "newpassword123"
    }
    resp = client.post("/api/v1/auth/recover-password", json=payload)
    assert resp.status_code == 400
    assert "Los datos proporcionados no coinciden" in resp.json()["detail"]
