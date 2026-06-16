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

## Flujo de demostración sugerido

1. Ejecutar `trigger_pass.py` → mostrar pipeline verde
2. Ejecutar `trigger_fail.py` → mostrar pipeline rojo + Telegram
3. Ejecutar `cleanup_fail.py` → restaurar estado correcto
4. Verificar en GitHub Actions el historial de ejecuciones
