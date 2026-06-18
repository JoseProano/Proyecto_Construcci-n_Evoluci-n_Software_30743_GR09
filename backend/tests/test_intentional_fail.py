"""
AmazonFish – TEST DE FALLO INTENCIONAL
Generado por: scripts/trigger_fail.py
Timestamp: 2026-06-17T19:21:47.332217

PROPÓSITO: Demostrar que el pipeline CI/CD detecta errores.
Este test SIEMPRE falla. Para revertir: python scripts/cleanup_fail.py
"""
import pytest


def test_fallo_intencional():
    """
    Este test SIEMPRE falla.
    Demuestra que el pipeline detecta errores y notifica por Telegram.
    """
    assert False, (
        "❌ FALLO INTENCIONAL – Pipeline detectando errores correctamente. "
        "Ejecuta: python scripts/cleanup_fail.py para revertir."
    )
