#!/usr/bin/env python3
"""
AmazonFish – Script: Disparar Pipeline EXITOSO
Actualiza backend/version.py con timestamp y hace push.
Esto dispara el pipeline CI/CD que PASARÁ todas las etapas.

Uso:
    cd Proyecto_AmazonFish
    python scripts/trigger_pass.py
"""
import subprocess
import datetime
import os
import sys

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
VERSION_FILE = os.path.join(BASE_DIR, "backend", "version.py")

def run(cmd: str) -> None:
    """Ejecuta un comando de shell."""
    print(f"  $ {cmd}")
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True, cwd=BASE_DIR)
    if result.returncode != 0:
        print(f"  ❌ Error: {result.stderr.strip() or result.stdout.strip()}")
        sys.exit(1)
    if result.stdout.strip():
        print(f"  {result.stdout.strip()}")

def main():
    print("=" * 60)
    print("✅ AmazonFish – Disparar Pipeline EXITOSO")
    print("=" * 60)

    timestamp = datetime.datetime.now().isoformat()
    version = "1.0.0"

    print(f"\n📝 Actualizando {VERSION_FILE}...")
    with open(VERSION_FILE, "w", encoding="utf-8") as f:
        f.write(f"# AmazonFish Backend – Version File\n")
        f.write(f"# Actualizado automáticamente por trigger_pass.py\n")
        f.write(f'VERSION = "{version}"\n')
        f.write(f'BUILD_DATE = "{timestamp[:19]}"\n')
        f.write(f'BUILD_TRIGGER = "pass_test"\n')
    print(f"  ✅ version.py actualizado: {timestamp}")

    print("\n🔧 Realizando commit y push...")
    run('git add backend/version.py')
    run(f'git commit -m "ci: trigger pass test [{timestamp[:19]}]"')
    run('git push')

    print("\n" + "=" * 60)
    print("✅ Push completado. El pipeline iniciará automáticamente.")
    print("📊 Revisa: https://github.com/JoseProano/Proyecto_Construcci-n_Evoluci-n_Software_30743_GR09/actions")
    print("📱 Telegram recibirá notificación al finalizar.")
    print("=" * 60)

if __name__ == "__main__":
    main()
