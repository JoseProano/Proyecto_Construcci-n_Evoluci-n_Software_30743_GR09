"""
AmazonFish – Tests: Módulo de Usuarios
Verifica creación con hash de contraseña, validaciones y relación Persona 1:1 Usuario.
"""
import pytest
from models import Persona


class TestUsuarios:
    """Suite de pruebas para el módulo de Usuarios."""

    def _crear_persona(self, client, auth_headers, identificacion, correo):
        """Helper: crea una persona de apoyo para los tests."""
        resp = client.post("/api/v1/personas/", json={
            "nombres": "Test",
            "apellidos": "User",
            "identificacion": identificacion,
            "correo": correo,
        }, headers=auth_headers)
        assert resp.status_code == 201
        return resp.json()["id_persona"]

    def test_listar_usuarios_incluye_roles(self, client, auth_headers):
        """Los usuarios deben venir con sus roles asignados."""
        resp = client.get("/api/v1/usuarios/", headers=auth_headers)
        assert resp.status_code == 200
        usuarios = resp.json()
        assert isinstance(usuarios, list)
        for u in usuarios:
            assert "roles" in u

    def test_crear_usuario_exitosamente(self, client, auth_headers):
        """POST /usuarios/ con datos válidos debe crear el usuario con hash."""
        id_p = self._crear_persona(client, auth_headers, "2222222222", "nuevo@amazonfish.test")
        resp = client.post("/api/v1/usuarios/", json={
            "id_persona": id_p,
            "username": "nuevo_vendedor",
            "password": "password123",
        }, headers=auth_headers)
        assert resp.status_code == 201
        body = resp.json()
        assert body["username"] == "nuevo_vendedor"
        assert "password_hash" not in body  # El hash no debe exponerse

    def test_password_muy_corta_rechazada(self, client, auth_headers):
        """Contraseñas de menos de 8 caracteres deben rechazarse (422)."""
        id_p = self._crear_persona(client, auth_headers, "3333333333", "short@test.com")
        resp = client.post("/api/v1/usuarios/", json={
            "id_persona": id_p,
            "username": "corto_pwd",
            "password": "1234",  # muy corta
        }, headers=auth_headers)
        assert resp.status_code == 422

    def test_persona_sin_usuario_es_requerida(self, client, auth_headers):
        """Crear usuario con persona inexistente debe retornar 404."""
        resp = client.post("/api/v1/usuarios/", json={
            "id_persona": "persona-no-existe",
            "username": "sin_persona",
            "password": "password123",
        }, headers=auth_headers)
        assert resp.status_code == 404

    def test_persona_ya_tiene_usuario_rechazada(self, client, auth_headers):
        """Una persona que ya tiene usuario no puede tener otro (400)."""
        # El seed ya creó usuario para persona-test-001
        resp = client.post("/api/v1/usuarios/", json={
            "id_persona": "persona-test-001",
            "username": "otro_usuario",
            "password": "password123",
        }, headers=auth_headers)
        assert resp.status_code == 400

    def test_username_duplicado_rechazado(self, client, auth_headers):
        """El username debe ser único en el sistema."""
        id_p = self._crear_persona(client, auth_headers, "4444444444", "dup@test.com")
        resp = client.post("/api/v1/usuarios/", json={
            "id_persona": id_p,
            "username": "admin_test",  # ya existe en seed
            "password": "password123",
        }, headers=auth_headers)
        assert resp.status_code == 400

    def test_obtener_usuario_por_id(self, client, auth_headers):
        """GET /usuarios/{id} debe retornar el usuario con sus roles."""
        resp = client.get("/api/v1/usuarios/usuario-test-001", headers=auth_headers)
        assert resp.status_code == 200
        body = resp.json()
        assert body["id_usuario"] == "usuario-test-001"
        assert "roles" in body

    def test_eliminar_usuario_logicamente(self, client, auth_headers):
        """DELETE debe desactivar el usuario sin borrarlo físicamente."""
        id_p = self._crear_persona(client, auth_headers, "5555555555", "del.user@test.com")
        create = client.post("/api/v1/usuarios/", json={
            "id_persona": id_p,
            "username": "user_to_delete",
            "password": "password123",
        }, headers=auth_headers)
        assert create.status_code == 201
        id_u = create.json()["id_usuario"]

        del_resp = client.delete(f"/api/v1/usuarios/{id_u}", headers=auth_headers)
        assert del_resp.status_code == 204
