-- ================================================================
-- AmazonFish – Migración 01: Personas, Usuarios y Roles
-- Módulo transversal obligatorio del proyecto
-- Reglas:
--   • Persona separada de Usuario
--   • Persona 1──1 Usuario
--   • Usuario N──M Rol (tabla intermedia usuario_rol)
--   • UUID como clave primaria
--   • Contraseñas almacenadas como password_hash (bcrypt)
-- ================================================================

-- Extensión para generación de UUID
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ── ROLES ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS roles (
    id_rol           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nombre           VARCHAR(50)  NOT NULL UNIQUE,
    descripcion      TEXT,
    estado           BOOLEAN      NOT NULL DEFAULT TRUE,
    fecha_creacion   TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE  roles IS 'Roles del sistema: administrador, vendedor, socio';
COMMENT ON COLUMN roles.id_rol IS 'UUID v4 – clave primaria';
COMMENT ON COLUMN roles.nombre IS 'Nombre único del rol';

-- ── PERSONAS ──────────────────────────────────────────────────────
-- Datos personales independientes de las credenciales de acceso
CREATE TABLE IF NOT EXISTS personas (
    id_persona       UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nombres          VARCHAR(100) NOT NULL,
    apellidos        VARCHAR(100) NOT NULL,
    identificacion   VARCHAR(20)  NOT NULL UNIQUE,
    correo           VARCHAR(150) NOT NULL UNIQUE,
    telefono         VARCHAR(20),
    estado           BOOLEAN      NOT NULL DEFAULT TRUE,
    fecha_creacion   TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE  personas IS 'Datos personales: separados de credenciales de acceso';
COMMENT ON COLUMN personas.id_persona IS 'UUID v4 – clave primaria';

-- ── USUARIOS ──────────────────────────────────────────────────────
-- Credenciales de acceso. NUNCA password en texto plano.
CREATE TABLE IF NOT EXISTS usuarios (
    id_usuario       UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    id_persona       UUID         NOT NULL UNIQUE
                         REFERENCES personas(id_persona) ON DELETE RESTRICT,
    username         VARCHAR(50)  NOT NULL UNIQUE,
    password_hash    VARCHAR(255) NOT NULL,   -- bcrypt hash, NUNCA texto plano
    estado           BOOLEAN      NOT NULL DEFAULT TRUE,
    fecha_creacion   TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    ultimo_acceso    TIMESTAMPTZ
);

COMMENT ON TABLE  usuarios IS 'Credenciales de acceso (1:1 con Persona)';
COMMENT ON COLUMN usuarios.password_hash IS 'Hash bcrypt – NUNCA texto plano';
COMMENT ON COLUMN usuarios.id_persona IS 'Relación 1:1 con Persona (UNIQUE)';

-- ── USUARIO_ROL ───────────────────────────────────────────────────
-- Tabla intermedia para la relación N:M Usuario ↔ Rol
CREATE TABLE IF NOT EXISTS usuario_rol (
    id_usuario_rol   UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    id_usuario       UUID        NOT NULL REFERENCES usuarios(id_usuario) ON DELETE CASCADE,
    id_rol           UUID        NOT NULL REFERENCES roles(id_rol)    ON DELETE RESTRICT,
    fecha_asignacion TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    estado           BOOLEAN     NOT NULL DEFAULT TRUE,
    CONSTRAINT uq_usuario_rol UNIQUE (id_usuario, id_rol)
);

COMMENT ON TABLE usuario_rol IS 'Tabla intermedia N:M: Usuario ↔ Rol';

-- ── ÍNDICES ───────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_usuarios_username   ON usuarios(username);
CREATE INDEX IF NOT EXISTS idx_personas_correo     ON personas(correo);
CREATE INDEX IF NOT EXISTS idx_usuario_rol_usuario ON usuario_rol(id_usuario);
CREATE INDEX IF NOT EXISTS idx_usuario_rol_rol     ON usuario_rol(id_rol);

-- ── ROLES PREDEFINIDOS ────────────────────────────────────────────
INSERT INTO roles (nombre, descripcion) VALUES
    ('administrador', 'Control total: inventario, ventas, reportes y configuración del sistema'),
    ('vendedor',      'Armar pedidos, registrar cobros y consultar inventario'),
    ('socio',         'Cliente acuícola: ver catálogo, crear pedidos y consultar historial')
ON CONFLICT (nombre) DO NOTHING;
