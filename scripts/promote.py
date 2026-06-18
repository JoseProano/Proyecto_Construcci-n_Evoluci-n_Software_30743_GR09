#!/usr/bin/env python3
"""
AmazonFish – Script: Promover Cambios de develop a main
Fusiona la rama de desarrollo (develop) en main y hace push.
Esto dispara el pipeline CI/CD completo con DEPLOY, RELEASE y GITHUB PAGES.

Uso:
    python scripts/promote.py
"""
import subprocess
import os
import sys

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

def run(cmd: str) -> str:
    print(f"  $ {cmd}")
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True, cwd=BASE_DIR)
    if result.returncode != 0:
        print(f"  ❌ Error: {result.stderr.strip()}")
        sys.exit(1)
    return result.stdout.strip()

def get_current_branch() -> str:
    return run("git rev-parse --abbrev-ref HEAD")

def main():
    print("=" * 60)
    print("🚀 AmazonFish – Promoción de Cambios a Producción (main)")
    print("=" * 60)

    # 1. Obtener rama actual
    current_branch = get_current_branch()
    print(f"\nRama actual: {current_branch}")

    if current_branch == "main":
        print("⚠️ Ya te encuentras en la rama main. No hay nada que promover de forma externa.")
        print("Si tienes cambios locales en main, simplemente haz: git push")
        sys.exit(0)

    # Confirmar si se promueve la rama actual
    print(f"\nSe fusionarán los cambios de '{current_branch}' en 'main'.")
    
    # Asegurar que no hay cambios locales sin guardar
    status = run("git status --porcelain")
    if status:
        print("❌ Error: Tienes cambios locales sin guardar en Git. Haz commit o stash antes de continuar.")
        print(status)
        sys.exit(1)

    print("\n🔄 1. Actualizando repositorio remoto...")
    run("git fetch origin")

    print("\n🔄 2. Cambiando a rama main...")
    run("git checkout main")

    print("\n🔄 3. Actualizando rama main local con el servidor...")
    run("git pull origin main")

    print(f"\n🔄 4. Fusionando '{current_branch}' en 'main'...")
    # Usamos --no-edit para aceptar el mensaje de merge por defecto
    run(f"git merge {current_branch} --no-edit")

    print("\n🚀 5. Subiendo cambios a main en GitHub...")
    run("git push origin main")

    print(f"\n🔄 6. Regresando a tu rama original '{current_branch}'...")
    run(f"git checkout {current_branch}")

    print("\n" + "=" * 60)
    print("✅ ¡Promoción exitosa!")
    print("📊 El pipeline completo de deploys iniciará en la rama main.")
    print("📱 Telegram recibirá notificaciones del inicio y fin del deployment.")
    print("=" * 60)

if __name__ == "__main__":
    main()
