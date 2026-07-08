#!/usr/bin/env python3
"""
AmazonFish – Script: Disparar Pipeline FALLIDO
Crea un test que SIEMPRE falla y hace push.
Esto dispara el pipeline CI/CD que FALLARÁ en la etapa de tests.
Útil para demostrar que el pipeline detecta errores correctamente.

Uso:
    cd Proyecto_AmazonFish
    python scripts/trigger_fail.py

Para restaurar (pasar a estado exitoso):
    python scripts/cleanup_fail.py
"""
import subprocess
import datetime
import os
import sys

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FAIL_TEST_FILE = os.path.join(BASE_DIR, "backend", "tests", "test_intentional_fail.py")

def run(cmd: str) -> None:
    print(f"  $ {cmd}")
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True, cwd=BASE_DIR)
    if result.returncode != 0:
        print(f"  ❌ Error: {result.stderr.strip() or result.stdout.strip()}")
        sys.exit(1)
    if result.stdout.strip():
        print(f"  {result.stdout.strip()}")

def main():
    print("=" * 60)
    print("❌ AmazonFish – Disparar Pipeline FALLIDO (intencional)")
    print("=" * 60)

    timestamp = datetime.datetime.now().isoformat()

    print(f"\n⚠️  Creando test de fallo intencional...")
    content = f'''"""
AmazonFish – TEST DE FALLO INTENCIONAL
Generado por: scripts/trigger_fail.py
Timestamp: {timestamp}

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
'''
    with open(FAIL_TEST_FILE, "w", encoding="utf-8") as f:
        f.write(content)
    print(f"  ✅ Test de fallo creado en: {FAIL_TEST_FILE}")

    print("\n🔧 Realizando commit y push...")
    run('git add backend/tests/test_intentional_fail.py')
    run(f'git commit -m "test: intentional fail [{timestamp[:19]}]"')
    run('git push')

    print("\n" + "=" * 60)
    print("⚠️  Push completado. El pipeline FALLARÁ en la etapa de tests.")
    print("📱 Telegram recibirá notificación de FALLO.")
    print("\n🔄 Para restaurar el estado exitoso, ejecuta:")
    print("   python scripts/cleanup_fail.py")
    print("=" * 60)

if __name__ == "__main__":
    main()
