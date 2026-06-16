"""
AmazonFish – Servicio: Factory Method para Productos Acuícolas
Implementa el patrón de diseño Factory Method (GoF) para crear productos
con código dinámico autogenerado: PROD-BAL-2026-0001, PROD-INS-2026-0002…

Jerarquía:
    ProductoAcuicolaFactory (abstract)
    ├── BalanceadoFactory      → PROD-BAL-YYYY-NNNN
    ├── InsumoFactory          → PROD-INS-YYYY-NNNN
    ├── MedicamentoFactory     → PROD-MED-YYYY-NNNN
    └── EquipoFactory          → PROD-EQU-YYYY-NNNN
"""
from abc import ABC, abstractmethod
from datetime import datetime
from sqlalchemy.orm import Session

from models import (
    ProductoAcuicola,
    Balanceado,
    InsumoAcuicola,
    MedicamentoAcuicola,
    EquipoAcuicola,
)


class ProductoAcuicolaFactory(ABC):
    """
    Clase base abstracta para las fábricas de productos.
    Define el Factory Method 'crear()' y la generación del código legible.
    """

    @abstractmethod
    def get_tipo_codigo(self) -> str:
        """Retorna el prefijo de 3 letras del tipo (BAL, INS, MED, EQU)."""

    @abstractmethod
    def _instanciar(self, datos: dict) -> ProductoAcuicola:
        """Crea y retorna la instancia concreta del producto."""

    def generar_codigo(self, secuencia: int) -> str:
        """
        Genera el código legible con formato: PROD-XXX-YYYY-NNNN
        Ejemplo: PROD-BAL-2026-0001
        """
        anio = datetime.now().year
        return f"PROD-{self.get_tipo_codigo()}-{anio}-{secuencia:04d}"

    def _siguiente_secuencia(self, db: Session) -> int:
        """Calcula la siguiente secuencia global de productos."""
        return db.query(ProductoAcuicola).count() + 1

    def crear(self, datos: dict, db: Session) -> ProductoAcuicola:
        """
        Factory Method: crea el producto con código autogenerado.
        Este método coordina la generación del código y la creación del objeto.
        """
        seq = self._siguiente_secuencia(db)
        datos["codigo_producto"] = self.generar_codigo(seq)
        return self._instanciar(datos)


# ── Fábricas concretas ───────────────────────────────────────────

class BalanceadoFactory(ProductoAcuicolaFactory):
    """Fábrica para alimentos balanceados (tilapia, camarón, trucha…)."""

    def get_tipo_codigo(self) -> str:
        return "BAL"

    def _instanciar(self, datos: dict) -> Balanceado:
        campos_especificos = {"tipo_especie", "etapa_vida"}
        base = {k: v for k, v in datos.items() if k not in campos_especificos}
        extra = {k: datos.get(k) for k in campos_especificos}
        return Balanceado(tipo_producto="balanceado", **base, **extra)


class InsumoFactory(ProductoAcuicolaFactory):
    """Fábrica para insumos acuícolas (probióticos, minerales, vitaminas…)."""

    def get_tipo_codigo(self) -> str:
        return "INS"

    def _instanciar(self, datos: dict) -> InsumoAcuicola:
        campos_especificos = {"tipo_insumo", "aplicacion"}
        base = {k: v for k, v in datos.items() if k not in campos_especificos}
        extra = {k: datos.get(k) for k in campos_especificos}
        return InsumoAcuicola(tipo_producto="insumo", **base, **extra)


class MedicamentoFactory(ProductoAcuicolaFactory):
    """Fábrica para medicamentos veterinarios acuícolas."""

    def get_tipo_codigo(self) -> str:
        return "MED"

    def _instanciar(self, datos: dict) -> MedicamentoAcuicola:
        campos_especificos = {"principio_activo", "dosis_recomendada", "registro_sanitario"}
        base = {k: v for k, v in datos.items() if k not in campos_especificos}
        extra = {k: datos.get(k) for k in campos_especificos}
        return MedicamentoAcuicola(tipo_producto="medicamento", **base, **extra)


class EquipoFactory(ProductoAcuicolaFactory):
    """Fábrica para equipos y maquinaria acuícola."""

    def get_tipo_codigo(self) -> str:
        return "EQU"

    def _instanciar(self, datos: dict) -> EquipoAcuicola:
        campos_especificos = {"marca", "modelo", "garantia_meses"}
        base = {k: v for k, v in datos.items() if k not in campos_especificos}
        extra = {k: datos.get(k) for k in campos_especificos}
        return EquipoAcuicola(tipo_producto="equipo", **base, **extra)


# ── Registro de fábricas (simple factory registry) ───────────────

_REGISTRY: dict[str, ProductoAcuicolaFactory] = {
    "balanceado": BalanceadoFactory(),
    "insumo":     InsumoFactory(),
    "medicamento": MedicamentoFactory(),
    "equipo":     EquipoFactory(),
}


def get_factory(tipo: str) -> ProductoAcuicolaFactory:
    """
    Retorna la fábrica correspondiente al tipo de producto.
    Lanza ValueError si el tipo no está registrado.
    """
    factory = _REGISTRY.get(tipo.lower())
    if factory is None:
        raise ValueError(
            f"Tipo de producto no válido: '{tipo}'. "
            f"Opciones disponibles: {list(_REGISTRY.keys())}"
        )
    return factory
