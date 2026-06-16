#!/usr/bin/env python3
"""
AmazonFish – Script: Limpiar test de fallo y restaurar pipeline
Elimina el test de fallo intencional y vuelve al estado exitoso.

Uso:
    cd Proyecto_AmazonFish
    python scripts/cleanup_fail.py
"""
import subprocess
import os
import sys

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FAIL_TEST_FILE = os.path.join(BASE_DIR, "backend", "tests", "test_intentional_fail.py")

def run(cmd: str) -> None:
    print(f"  $ {cmd}")
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True, cwd=BASE_DIR)
    if result.returncode != 0:
        print(f"  ⚠️  {result.stderr.strip() or 'Sin cambios'}")
    if result.stdout.strip():
        print(f"  {result.stdout.strip()}")

def main():
    print("=" * 60)
    print("🔄 AmazonFish – Restaurar pipeline al estado exitoso")
    print("=" * 60)

    if os.path.exists(FAIL_TEST_FILE):
        os.remove(FAIL_TEST_FILE)
        print(f"\n✅ Test de fallo eliminado: {FAIL_TEST_FILE}")

        run('git add -A')
        run('git commit -m "ci: restore pipeline to passing state"')
        run('git push')

        print("\n✅ Pipeline restaurado. El próximo run PASARÁ todas las etapas.")
        print("📱 Telegram recibirá notificación de ÉXITO.")
    else:
        print("\nℹ️  No hay test de fallo activo. El pipeline ya está en estado correcto.")

    print("=" * 60)

if __name__ == "__main__":
    main()
