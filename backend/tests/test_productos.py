"""
AmazonFish – Tests: Factory Method y Productos Acuícolas
Verifica el patrón Factory Method, la generación de códigos dinámicos
y los endpoints de creación de cada tipo de producto.
"""
import pytest
from services.producto_factory import (
    get_factory,
    BalanceadoFactory,
    InsumoFactory,
    MedicamentoFactory,
    EquipoFactory,
)


class TestProductoFactory:
    """Pruebas unitarias del patrón Factory Method."""

    def test_factory_balanceado_retorna_instancia(self):
        factory = get_factory("balanceado")
        assert isinstance(factory, BalanceadoFactory)

    def test_factory_insumo_retorna_instancia(self):
        factory = get_factory("insumo")
        assert isinstance(factory, InsumoFactory)

    def test_factory_medicamento_retorna_instancia(self):
        factory = get_factory("medicamento")
        assert isinstance(factory, MedicamentoFactory)

    def test_factory_equipo_retorna_instancia(self):
        factory = get_factory("equipo")
        assert isinstance(factory, EquipoFactory)

    def test_factory_tipo_invalido_lanza_error(self):
        """Un tipo no registrado debe lanzar ValueError."""
        with pytest.raises(ValueError, match="no válido"):
            get_factory("peces")

    def test_codigo_balanceado_formato_correcto(self):
        """El código debe seguir: PROD-BAL-YYYY-NNNN."""
        factory = BalanceadoFactory()
        codigo = factory.generar_codigo(1)
        partes = codigo.split("-")
        assert len(partes) == 4
        assert partes[0] == "PROD"
        assert partes[1] == "BAL"
        assert len(partes[2]) == 4  # año
        assert partes[3] == "0001"

    def test_codigo_insumo_formato_correcto(self):
        factory = InsumoFactory()
        codigo = factory.generar_codigo(5)
        assert codigo.startswith("PROD-INS-")
        assert codigo.endswith("0005")

    def test_codigo_medicamento_formato_correcto(self):
        factory = MedicamentoFactory()
        codigo = factory.generar_codigo(10)
        assert codigo.startswith("PROD-MED-")
        assert codigo.endswith("0010")

    def test_codigo_equipo_formato_correcto(self):
        factory = EquipoFactory()
        codigo = factory.generar_codigo(99)
        assert codigo.startswith("PROD-EQU-")
        assert codigo.endswith("0099")

    def test_codigos_son_secuenciales(self):
        """Dos productos deben tener códigos distintos y secuenciales."""
        factory = BalanceadoFactory()
        cod1 = factory.generar_codigo(1)
        cod2 = factory.generar_codigo(2)
        assert cod1 != cod2
        assert cod1.endswith("0001")
        assert cod2.endswith("0002")

    def test_todos_los_tipos_tienen_factory(self):
        """Cada tipo definido debe tener su fábrica registrada."""
        for tipo in ["balanceado", "insumo", "medicamento", "equipo"]:
            f = get_factory(tipo)
            assert f is not None
            assert callable(getattr(f, "crear", None))


class TestProductosEndpoints:
    """Pruebas de integración para los endpoints de productos."""

    def test_crear_balanceado_exitosamente(self, client, auth_headers):
        """POST /productos/balanceado debe crear producto con código autogenerado."""
        resp = client.post("/api/v1/productos/balanceado", json={
            "nombre": "Balanceado Tilapia 45% Proteína",
            "precio_unitario": 62.50,
            "stock_actual": 100,
            "stock_minimo": 20,
            "unidad_medida": "sacos 40kg",
            "tipo_especie": "tilapia",
            "etapa_vida": "engorde",
        }, headers=auth_headers)
        assert resp.status_code == 201
        body = resp.json()
        assert body["codigo_producto"].startswith("PROD-BAL-")
        assert body["tipo_producto"] == "balanceado"
        assert body["nombre"] == "Balanceado Tilapia 45% Proteína"

    def test_crear_insumo_exitosamente(self, client, auth_headers):
        """POST /productos/insumo debe crear insumo con código PROD-INS-."""
        resp = client.post("/api/v1/productos/insumo", json={
            "nombre": "Probiótico AquaPro 500g",
            "precio_unitario": 28.00,
            "stock_actual": 50,
            "tipo_insumo": "probiótico",
            "aplicacion": "Mejorar conversión alimenticia",
        }, headers=auth_headers)
        assert resp.status_code == 201
        assert resp.json()["codigo_producto"].startswith("PROD-INS-")

    def test_listar_productos_retorna_lista(self, client, auth_headers):
        """GET /productos/ debe retornar una lista."""
        resp = client.get("/api/v1/productos/", headers=auth_headers)
        assert resp.status_code == 200
        assert isinstance(resp.json(), list)

    def test_filtrar_productos_por_tipo(self, client, auth_headers):
        """GET /productos/?tipo=balanceado debe filtrar correctamente."""
        # Crear un balanceado primero
        client.post("/api/v1/productos/balanceado", json={
            "nombre": "Filtro Test",
            "precio_unitario": 50.0,
            "stock_actual": 10,
        }, headers=auth_headers)

        resp = client.get("/api/v1/productos/?tipo=balanceado", headers=auth_headers)
        assert resp.status_code == 200
        for p in resp.json():
            assert p["tipo_producto"] == "balanceado"

    def test_producto_inexistente_retorna_404(self, client, auth_headers):
        resp = client.get("/api/v1/productos/no-existe", headers=auth_headers)
        assert resp.status_code == 404

    def test_health_check(self, client):
        """El endpoint de salud debe estar disponible sin autenticación."""
        resp = client.get("/health")
        assert resp.status_code == 200
        assert resp.json()["status"] == "healthy"
