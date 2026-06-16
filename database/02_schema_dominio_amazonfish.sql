-- ================================================================
-- AmazonFish – Migración 02: Dominio Acuícola
-- Proveedores (herencia) y Productos Acuícolas (herencia + Factory)
--
-- Herencia implementada con "joined table inheritance":
--   Proveedor → proveedores_persona_natural
--              → proveedores_persona_juridica
--
--   ProductoAcuicola → balanceados
--                    → insumos_acuicola
--                    → medicamentos_acuicola
--                    → equipos_acuicola
--
-- Código dinámico: PROD-BAL-2026-0001 (generado por función SQL)
-- ================================================================

-- ── PROVEEDORES (tabla base) ──────────────────────────────────────
CREATE TABLE IF NOT EXISTS proveedores (
    id_proveedor     UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    razon_social     VARCHAR(200) NOT NULL,
    correo           VARCHAR(150),
    telefono         VARCHAR(20),
    direccion        TEXT,
    estado           BOOLEAN      NOT NULL DEFAULT TRUE,
    tipo_proveedor   VARCHAR(20)  NOT NULL CHECK (tipo_proveedor IN ('natural','juridico')),
    fecha_registro   TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE proveedores IS 'Clase base abstracta de proveedores (joined table inheritance)';

-- ── PROVEEDOR PERSONA NATURAL ─────────────────────────────────────
CREATE TABLE IF NOT EXISTS proveedores_persona_natural (
    id_proveedor     UUID PRIMARY KEY
                         REFERENCES proveedores(id_proveedor) ON DELETE CASCADE,
    nombres          VARCHAR(100),
    apellidos        VARCHAR(100),
    cedula           VARCHAR(20)
);

-- ── PROVEEDOR PERSONA JURÍDICA ────────────────────────────────────
CREATE TABLE IF NOT EXISTS proveedores_persona_juridica (
    id_proveedor         UUID PRIMARY KEY
                             REFERENCES proveedores(id_proveedor) ON DELETE CASCADE,
    ruc                  VARCHAR(15),
    nombre_comercial     VARCHAR(200),
    representante_legal  VARCHAR(200)
);

-- ── PRODUCTOS ACUÍCOLAS (tabla base) ─────────────────────────────
CREATE TABLE IF NOT EXISTS productos_acuicola (
    id_producto      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    codigo_producto  VARCHAR(30)    NOT NULL UNIQUE,  -- PROD-BAL-2026-0001
    nombre           VARCHAR(200)   NOT NULL,
    descripcion      TEXT,
    precio_unitario  NUMERIC(10,2)  NOT NULL CHECK (precio_unitario >= 0),
    stock_actual     NUMERIC(10,2)  NOT NULL DEFAULT 0 CHECK (stock_actual >= 0),
    stock_minimo     NUMERIC(10,2)  NOT NULL DEFAULT 0,
    unidad_medida    VARCHAR(20)    NOT NULL DEFAULT 'kg',
    estado           BOOLEAN        NOT NULL DEFAULT TRUE,
    tipo_producto    VARCHAR(20)    NOT NULL
                         CHECK (tipo_producto IN ('balanceado','insumo','medicamento','equipo')),
    id_proveedor     UUID REFERENCES proveedores(id_proveedor),
    fecha_registro   TIMESTAMPTZ    NOT NULL DEFAULT NOW()
);

COMMENT ON COLUMN productos_acuicola.codigo_producto
    IS 'Código legible generado por Factory Method: PROD-XXX-YYYY-NNNN';

-- ── BALANCEADOS ───────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS balanceados (
    id_producto      UUID PRIMARY KEY
                         REFERENCES productos_acuicola(id_producto) ON DELETE CASCADE,
    tipo_especie     VARCHAR(50),   -- tilapia, camarón, trucha
    etapa_vida       VARCHAR(50)    -- iniciación, crecimiento, engorde
);

-- ── INSUMOS ACUÍCOLAS ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS insumos_acuicola (
    id_producto      UUID PRIMARY KEY
                         REFERENCES productos_acuicola(id_producto) ON DELETE CASCADE,
    tipo_insumo      VARCHAR(50),
    aplicacion       TEXT
);

-- ── MEDICAMENTOS ACUÍCOLAS ────────────────────────────────────────
CREATE TABLE IF NOT EXISTS medicamentos_acuicola (
    id_producto         UUID PRIMARY KEY
                            REFERENCES productos_acuicola(id_producto) ON DELETE CASCADE,
    principio_activo    VARCHAR(100),
    dosis_recomendada   VARCHAR(100),
    registro_sanitario  VARCHAR(50)
);

-- ── EQUIPOS ACUÍCOLAS ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS equipos_acuicola (
    id_producto      UUID PRIMARY KEY
                         REFERENCES productos_acuicola(id_producto) ON DELETE CASCADE,
    marca            VARCHAR(50),
    modelo           VARCHAR(50),
    garantia_meses   INTEGER
);

-- ── FUNCIÓN: GENERADOR DE CÓDIGO DE PRODUCTO ─────────────────────
-- Implementa la lógica del Factory Method a nivel de base de datos
CREATE OR REPLACE FUNCTION generar_codigo_producto(p_tipo VARCHAR)
RETURNS VARCHAR AS $$
DECLARE
    v_prefijo   VARCHAR(3);
    v_secuencia INTEGER;
    v_anio      INTEGER;
BEGIN
    v_anio := EXTRACT(YEAR FROM NOW())::INTEGER;

    CASE p_tipo
        WHEN 'balanceado'  THEN v_prefijo := 'BAL';
        WHEN 'insumo'      THEN v_prefijo := 'INS';
        WHEN 'medicamento' THEN v_prefijo := 'MED';
        WHEN 'equipo'      THEN v_prefijo := 'EQU';
        ELSE RAISE EXCEPTION 'Tipo de producto no válido: %', p_tipo;
    END CASE;

    SELECT COUNT(*) + 1
      INTO v_secuencia
      FROM productos_acuicola
     WHERE tipo_producto = p_tipo;

    RETURN FORMAT('PROD-%s-%s-%s', v_prefijo, v_anio, LPAD(v_secuencia::TEXT, 4, '0'));
END;
$$ LANGUAGE plpgsql;

-- ── ÍNDICES ───────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_productos_tipo     ON productos_acuicola(tipo_producto);
CREATE INDEX IF NOT EXISTS idx_productos_codigo   ON productos_acuicola(codigo_producto);
CREATE INDEX IF NOT EXISTS idx_productos_proveedor ON productos_acuicola(id_proveedor);
CREATE INDEX IF NOT EXISTS idx_proveedores_tipo   ON proveedores(tipo_proveedor);
