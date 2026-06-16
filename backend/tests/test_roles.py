"""
AmazonFish – Tests: Módulo de Roles
Verifica CRUD de roles y asignación N:M Usuario-Rol.
"""
import pytest


class TestRoles:
    """Suite de pruebas para el módulo de Roles."""

    def test_listar_roles_incluye_predefinidos(self, client, auth_headers):
        """El sistema debe tener los 3 roles básicos predefinidos en el seed."""
        resp = client.get("/api/v1/roles/", headers=auth_headers)
        assert resp.status_code == 200
        nombres = [r["nombre"] for r in resp.json()]
        assert "administrador" in nombres
        assert "vendedor" in nombres
        assert "socio" in nombres

    def test_crear_rol_nuevo(self, client, auth_headers):
        """POST /roles/ con nombre único debe crear el rol."""
        resp = client.post("/api/v1/roles/", json={
            "nombre": "bodeguero",
            "descripcion": "Gestión de bodega y stock físico",
        }, headers=auth_headers)
        assert resp.status_code == 201
        body = resp.json()
        assert body["nombre"] == "bodeguero"
        assert "id_rol" in body
        assert body["estado"] is True

    def test_rol_duplicado_rechazado(self, client, auth_headers):
        """No se puede crear dos roles con el mismo nombre."""
        resp = client.post("/api/v1/roles/", json={
            "nombre": "administrador",  # ya existe en seed
            "descripcion": "Duplicado",
        }, headers=auth_headers)
        assert resp.status_code == 400

    def test_obtener_rol_por_id(self, client, auth_headers):
        """GET /roles/{id} debe retornar el rol correcto."""
        resp = client.get("/api/v1/roles/rol-admin-001", headers=auth_headers)
        assert resp.status_code == 200
        assert resp.json()["nombre"] == "administrador"

    def test_obtener_rol_inexistente_retorna_404(self, client, auth_headers):
        resp = client.get("/api/v1/roles/no-existe", headers=auth_headers)
        assert resp.status_code == 404

    def test_actualizar_descripcion_rol(self, client, auth_headers):
        """PUT /roles/{id} debe actualizar el rol."""
        resp = client.put("/api/v1/roles/rol-vende-001", json={
            "descripcion": "Vendedor actualizado"
        }, headers=auth_headers)
        assert resp.status_code == 200
        assert resp.json()["descripcion"] == "Vendedor actualizado"

    def test_asignar_rol_a_usuario(self, client, auth_headers):
        """POST /roles/asignar debe crear la relación Usuario-Rol."""
        resp = client.post("/api/v1/roles/asignar", json={
            "id_usuario": "usuario-test-001",
            "id_rol": "rol-socio-001",
        }, headers=auth_headers)
        # 201 si es nueva asignación, 400 si ya existe
        assert resp.status_code in [201, 400]

    def test_asignar_rol_usuario_inexistente_falla(self, client, auth_headers):
        """Asignar rol a usuario que no existe debe retornar 404."""
        resp = client.post("/api/v1/roles/asignar", json={
            "id_usuario": "usuario-no-existe",
            "id_rol": "rol-admin-001",
        }, headers=auth_headers)
        assert resp.status_code == 404

    def test_eliminar_rol_logicamente(self, client, auth_headers):
        """DELETE /roles/{id} debe desactivar el rol (estado=False)."""
        # Crear un rol temporal para eliminar
        create = client.post("/api/v1/roles/", json={
            "nombre": "rol_temporal_test",
            "descripcion": "Para eliminar",
        }, headers=auth_headers)
        assert create.status_code == 201
        id_rol = create.json()["id_rol"]

        del_resp = client.delete(f"/api/v1/roles/{id_rol}", headers=auth_headers)
        assert del_resp.status_code == 204
