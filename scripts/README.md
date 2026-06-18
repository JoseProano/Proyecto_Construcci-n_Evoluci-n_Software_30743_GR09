# 📜 Scripts de Prueba del Pipeline – AmazonFish GR09

Scripts para demostrar y probar el pipeline CI/CD fácilmente.

## Requisitos
- Python 3.x instalado
- Git configurado con acceso al repositorio
- Estar en la rama correcta (develop o feature/...)

## Scripts disponibles

### `trigger_pass.py` – Disparar pipeline EXITOSO
Actualiza `backend/version.py` con un timestamp y hace push.
El pipeline correrá y **PASARÁ** todas las etapas.

```bash
python scripts/trigger_pass.py
```

**Resultado esperado:**
- ✅ Tests backend pasan
- ✅ SonarCloud completa el análisis  
- ✅ APK construido correctamente
- ✅ (Si en main) Deploy a Render
- 📱 Telegram: notificación verde de éxito

---

### `trigger_fail.py` – Disparar pipeline FALLIDO (intencional)
Crea un test que siempre falla y hace push.
El pipeline **FALLARÁ** en la etapa de tests (intencional).

```bash
python scripts/trigger_fail.py
```

**Resultado esperado:**
- ❌ Tests backend FALLAN (intencionalmente)
- ⏭️ SonarCloud y APK se omiten
- 📱 Telegram: notificación roja de fallo

---

### `cleanup_fail.py` – Restaurar estado exitoso
Elimina el test de fallo y vuelve al pipeline exitoso.

```bash
python scripts/cleanup_fail.py
```

---

### `promote.py` – Promover cambios a producción (main)
Automatiza la fusión (merge) de la rama actual (por ejemplo, `develop`) hacia la rama `main` y realiza el push. 
Esto disparará el pipeline completo en `main` que realiza las etapas de:
- 🚀 Deploy a Render (Backend)
- 🏷️ Crear Release en GitHub (con el APK adjunto)
- 🌐 Deploy a GitHub Pages (Landing Page para descargar el APK)

```bash
python scripts/promote.py
```

---

## Flujo de demostración sugerido

1. Asegúrate de estar en `develop`: `git checkout develop`
2. Ejecutar `trigger_pass.py` → mostrar pipeline verde en `develop` (no despliega)
3. Ejecutar `trigger_fail.py` → mostrar pipeline rojo en `develop` + Telegram (detecta error)
4. Ejecutar `cleanup_fail.py` → restaurar estado correcto en `develop` (vuelve a verde)
5. Ejecutar `promote.py` → promueve los cambios a `main` y corre el pipeline completo (incluyendo Deploy backend, GitHub Release y GitHub Pages).
6. Verificar en GitHub Actions el historial de ejecuciones.

