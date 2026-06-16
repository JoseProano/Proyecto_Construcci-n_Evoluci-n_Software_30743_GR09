"""
AmazonFish – Tests: Módulo de Personas
Verifica CRUD completo, validaciones y eliminación lógica.
"""
import pytest


class TestPersonas:
    """Suite de pruebas para el módulo de Personas."""

    def test_listar_personas_retorna_lista(self, client, auth_headers):
        """GET /personas/ debe retornar una lista (puede estar vacía)."""
        resp = client.get("/api/v1/personas/", headers=auth_headers)
        assert resp.status_code == 200
        assert isinstance(resp.json(), list)

    def test_crear_persona_datos_validos(self, client, auth_headers):
        """POST /personas/ con datos correctos debe retornar 201."""
        payload = {
            "nombres": "Juan",
            "apellidos": "Pérez García",
            "identificacion": "1234567890",
            "correo": "juan.perez@amazonfish.test",
            "telefono": "0999123456",
        }
        resp = client.post("/api/v1/personas/", json=payload, headers=auth_headers)
        assert resp.status_code == 201
        body = resp.json()
        assert body["nombres"] == "Juan"
        assert body["apellidos"] == "Pérez García"
        assert "id_persona" in body
        assert body["estado"] is True

    def test_crear_persona_identificacion_duplicada_falla(self, client, auth_headers):
        """Dos personas con la misma identificación deben ser rechazadas (400)."""
        payload = {
            "nombres": "Duplicado",
            "apellidos": "Test",
            "identificacion": "9999999999",  # ya existe en seed
            "correo": "otro.correo@test.com",
        }
        resp = client.post("/api/v1/personas/", json=payload, headers=auth_headers)
        assert resp.status_code == 400

    def test_crear_persona_correo_duplicado_falla(self, client, auth_headers):
        """Dos personas con el mismo correo deben ser rechazadas (400)."""
        payload = {
            "nombres": "Otra Persona",
            "apellidos": "Test",
            "identificacion": "0000000001",
            "correo": "admin@test.amazonfish.com",  # ya existe en seed
        }
        resp = client.post("/api/v1/personas/", json=payload, headers=auth_headers)
        assert resp.status_code == 400

    def test_obtener_persona_existente(self, client, auth_headers):
        """GET /personas/{id} debe retornar la persona correcta."""
        resp = client.get("/api/v1/personas/persona-test-001", headers=auth_headers)
        assert resp.status_code == 200
        assert resp.json()["id_persona"] == "persona-test-001"
        assert resp.json()["nombres"] == "Admin"

    def test_obtener_persona_inexistente_retorna_404(self, client, auth_headers):
        """GET /personas/{id_no_existente} debe retornar 404."""
        resp = client.get("/api/v1/personas/no-existe-este-id", headers=auth_headers)
        assert resp.status_code == 404

    def test_actualizar_persona_telefono(self, client, auth_headers):
        """PUT /personas/{id} debe actualizar campos correctamente."""
        resp = client.put(
            "/api/v1/personas/persona-test-001",
            json={"telefono": "0987654321"},
            headers=auth_headers,
        )
        assert resp.status_code == 200
        assert resp.json()["telefono"] == "0987654321"

    def test_eliminar_persona_logicamente(self, client, auth_headers):
        """DELETE debe hacer eliminación lógica (estado=False, no borra el registro)."""
        # Crear persona para eliminar
        create = client.post("/api/v1/personas/", json={
            "nombres": "Para Eliminar",
            "apellidos": "Test",
            "identificacion": "1111111111",
            "correo": "delete.me@test.com",
        }, headers=auth_headers)
        assert create.status_code == 201
        id_p = create.json()["id_persona"]

        # Eliminar
        del_resp = client.delete(f"/api/v1/personas/{id_p}", headers=auth_headers)
        assert del_resp.status_code == 204

        # Verificar que ya no aparece en la lista
        get_resp = client.get(f"/api/v1/personas/{id_p}", headers=auth_headers)
        assert get_resp.status_code == 404

    def test_acceso_sin_token_rechazado(self, client):
        """Las rutas protegidas deben rechazar solicitudes sin token (403)."""
        resp = client.get("/api/v1/personas/")
        assert resp.status_code == 403
