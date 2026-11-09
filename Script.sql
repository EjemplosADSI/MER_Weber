-- =============================================================================
-- MySQL Script - Sistema de Comercialización e Inventario FIFO Weber
-- Proyecto: EjemplosADSI / MER_Weber (Versión 2.0 Optimizada y Auditada)
-- Autor original: Diego Alonso Ojeda Medina
-- =============================================================================

SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

CREATE SCHEMA IF NOT EXISTS `weber` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `weber`;

-- -----------------------------------------------------
-- Tabla `weber`.`departamentos`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `weber`.`departamentos` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `nombre` VARCHAR(200) NOT NULL COMMENT 'Nombre oficial del departamento',
  `codigo_dane` INT UNSIGNED NOT NULL COMMENT 'Código DANE de 2 dígitos',
  `region` ENUM('Caribe', 'Centro Oriente', 'Centro Sur', 'Eje Cafetero - Antioquia', 'Llano', 'Pacífico') NOT NULL,
  `estado` ENUM('Activo', 'Inactivo') NOT NULL DEFAULT 'Activo',
  `creado_en` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `actualizado_en` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `eliminado_en` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `departamentos_nombre_unique` (`nombre` ASC),
  UNIQUE INDEX `departamentos_codigo_dane_unique` (`codigo_dane` ASC),
  INDEX `departamentos_region_estado_idx` (`region` ASC, `estado` ASC)
) ENGINE = InnoDB DEFAULT CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = 'Departamentos de Colombia (DANE)';

-- -----------------------------------------------------
-- Tabla `weber`.`municipios`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `weber`.`municipios` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `nombre` VARCHAR(255) NOT NULL,
  `departamento_id` BIGINT UNSIGNED NOT NULL,
  `codigo_dane` INT UNSIGNED NOT NULL COMMENT 'Código DANE de 5 dígitos',
  `abreviatura` VARCHAR(10) NULL DEFAULT NULL,
  `estado` ENUM('Activo', 'Inactivo') NOT NULL DEFAULT 'Activo',
  `creado_en` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `actualizado_en` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `eliminado_en` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `municipios_codigo_dane_unique` (`codigo_dane` ASC),
  INDEX `municipios_departamento_nombre_idx` (`departamento_id` ASC, `nombre` ASC),
  INDEX `municipios_estado_idx` (`estado` ASC),
  CONSTRAINT `municipios_departamento_id_foreign`
    FOREIGN KEY (`departamento_id`)
    REFERENCES `weber`.`departamentos` (`id`)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE = InnoDB DEFAULT CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = 'Municipios de Colombia con códigos DANE';

-- -----------------------------------------------------
-- Tabla `weber`.`empresas`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `weber`.`empresas` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `nombre` VARCHAR(150) NOT NULL COMMENT 'Razón social completa',
  `nit` VARCHAR(20) NOT NULL COMMENT 'NIT o identificación tributaria con dígito de verificación',
  `telefono` VARCHAR(20) NULL DEFAULT NULL,
  `email` VARCHAR(100) NULL DEFAULT NULL COMMENT 'Email corporativo',
  `direccion` VARCHAR(300) NULL DEFAULT NULL,
  `municipio_id` BIGINT UNSIGNED NULL DEFAULT NULL,
  `tipo_empresa` ENUM('Persona Natural', 'SAS', 'LTDA', 'SA', 'Cooperativa', 'Fundación', 'Otro') NOT NULL DEFAULT 'SAS',
  `estado` ENUM('Activo', 'Inactivo', 'Suspendido') NOT NULL DEFAULT 'Activo',
  `metadatos` JSON NULL DEFAULT NULL,
  `creado_en` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `actualizado_en` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `eliminado_en` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `empresas_nit_unique` (`nit` ASC),
  INDEX `empresas_nombre_idx` (`nombre` ASC),
  INDEX `empresas_municipio_idx` (`municipio_id` ASC),
  CONSTRAINT `empresas_municipio_foreign`
    FOREIGN KEY (`municipio_id`)
    REFERENCES `weber`.`municipios` (`id`)
    ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE = InnoDB DEFAULT CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = 'Empresas u organizaciones del sistema';

-- -----------------------------------------------------
-- Tabla `weber`.`sucursales` (Bodegas y Sedes)
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `weber`.`sucursales` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `empresa_id` BIGINT UNSIGNED NOT NULL,
  `codigo` VARCHAR(30) NOT NULL COMMENT 'Código interno de la sucursal',
  `nombre` VARCHAR(100) NOT NULL,
  `direccion` VARCHAR(300) NOT NULL,
  `municipio_id` BIGINT UNSIGNED NOT NULL,
  `telefono` VARCHAR(20) NOT NULL,
  `email` VARCHAR(100) NULL DEFAULT NULL,
  `tipo` ENUM('Principal', 'Subsede', 'Punto de Venta', 'Bodega') NOT NULL DEFAULT 'Punto de Venta',
  `estado` ENUM('Activo', 'Inactivo', 'Mantenimiento') NOT NULL DEFAULT 'Activo',
  `configuracion` JSON NULL DEFAULT NULL,
  `creado_en` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `actualizado_en` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `eliminado_en` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  -- CORRECCIÓN H1: Índice único compuesto para permitir MÚLTIPLES sucursales por empresa
  UNIQUE INDEX `sucursales_empresa_codigo_unique` (`empresa_id` ASC, `codigo` ASC),
  INDEX `sucursales_municipio_idx` (`municipio_id` ASC),
  INDEX `sucursales_tipo_estado_idx` (`tipo` ASC, `estado` ASC),
  CONSTRAINT `sucursales_empresa_foreign`
    FOREIGN KEY (`empresa_id`)
    REFERENCES `weber`.`empresas` (`id`)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT `sucursales_municipio_foreign`
    FOREIGN KEY (`municipio_id`)
    REFERENCES `weber`.`municipios` (`id`)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE = InnoDB DEFAULT CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = 'Sucursales y bodegas independientes por empresa';

-- -----------------------------------------------------
-- Tabla `weber`.`usuarios` (Autenticación y Credenciales)
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `weber`.`usuarios` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `email` VARCHAR(120) NOT NULL,
  `password_hash` VARCHAR(255) NOT NULL,
  `nombre` VARCHAR(120) NOT NULL,
  `rol` ENUM('SuperAdmin', 'Administrador', 'Vendedor', 'Auditor') NOT NULL DEFAULT 'Vendedor',
  `debe_cambiar_contrasena` TINYINT(1) NOT NULL DEFAULT 0,
  `estado` ENUM('Activo', 'Inactivo', 'Bloqueado') NOT NULL DEFAULT 'Activo',
  `ultimo_login` TIMESTAMP NULL DEFAULT NULL,
  `creado_en` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `actualizado_en` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `eliminado_en` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `usuarios_email_unique` (`email` ASC),
  INDEX `usuarios_rol_estado_idx` (`rol` ASC, `estado` ASC)
) ENGINE = InnoDB DEFAULT CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = 'Cuentas de acceso y autenticación al sistema';

-- -----------------------------------------------------
-- Tabla `weber`.`usuario_sucursal` (Alcance de Acceso)
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `weber`.`usuario_sucursal` (
  `usuario_id` BIGINT UNSIGNED NOT NULL,
  `sucursal_id` BIGINT UNSIGNED NOT NULL,
  `es_administrador` TINYINT(1) NOT NULL DEFAULT 0 COMMENT '1 si administra esta sede específica',
  `creado_en` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`usuario_id`, `sucursal_id`),
  CONSTRAINT `usuario_sucursal_usuario_fk`
    FOREIGN KEY (`usuario_id`) REFERENCES `weber`.`usuarios` (`id`) ON DELETE CASCADE,
  CONSTRAINT `usuario_sucursal_sucursal_fk`
    FOREIGN KEY (`sucursal_id`) REFERENCES `weber`.`sucursales` (`id`) ON DELETE CASCADE
) ENGINE = InnoDB DEFAULT CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = 'Sucursales a las que tiene acceso un usuario (scoping)';

-- -----------------------------------------------------
-- Tabla `weber`.`personas` (Base de Datos de Personas)
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `weber`.`personas` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `usuario_id` BIGINT UNSIGNED NULL DEFAULT NULL COMMENT 'Opcional si tiene cuenta de acceso',
  `tipo_documento` ENUM('CC', 'CE', 'TI', 'RC', 'PAS', 'NIT', 'PPT') NOT NULL,
  `documento` VARCHAR(20) NOT NULL,
  `nombres` VARCHAR(80) NOT NULL,
  `apellidos` VARCHAR(80) NOT NULL,
  `telefono` VARCHAR(20) NULL DEFAULT NULL,
  `email` VARCHAR(100) NULL DEFAULT NULL,
  `direccion` VARCHAR(300) NULL DEFAULT NULL,
  `municipio_id` BIGINT UNSIGNED NULL DEFAULT NULL,
  `fecha_nacimiento` DATE NULL DEFAULT NULL,
  `genero` ENUM('Masculino', 'Femenino', 'Otro', 'No especifica') NOT NULL DEFAULT 'No especifica',
  `foto_url` VARCHAR(500) NULL DEFAULT NULL,
  `estado` ENUM('Activo', 'Inactivo') NOT NULL DEFAULT 'Activo',
  `creado_en` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `actualizado_en` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `eliminado_en` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `personas_documento_unique` (`tipo_documento` ASC, `documento` ASC),
  INDEX `personas_usuario_idx` (`usuario_id` ASC),
  INDEX `personas_municipio_idx` (`municipio_id` ASC),
  CONSTRAINT `personas_usuario_fk`
    FOREIGN KEY (`usuario_id`) REFERENCES `weber`.`usuarios` (`id`) ON DELETE SET NULL,
  CONSTRAINT `personas_municipio_fk`
    FOREIGN KEY (`municipio_id`) REFERENCES `weber`.`municipios` (`id`) ON DELETE SET NULL
) ENGINE = InnoDB DEFAULT CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = 'Datos personales de personas naturales';

-- -----------------------------------------------------
-- Tabla `weber`.`empleados` (Personal Vinculado)
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `weber`.`empleados` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `persona_id` BIGINT UNSIGNED NOT NULL,
  `sucursal_id` BIGINT UNSIGNED NOT NULL,
  `codigo_empleado` VARCHAR(20) NOT NULL,
  `cargo` VARCHAR(60) NOT NULL DEFAULT 'Vendedor',
  `fecha_contratacion` DATE NOT NULL,
  `fecha_terminacion` DATE NULL DEFAULT NULL,
  `salario` DECIMAL(12,2) UNSIGNED NULL DEFAULT NULL,
  `estado` ENUM('Activo', 'Inactivo', 'Vacaciones', 'Retirado') NOT NULL DEFAULT 'Activo',
  `creado_en` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `actualizado_en` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `eliminado_en` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `empleados_persona_unique` (`persona_id` ASC),
  UNIQUE INDEX `empleados_codigo_unique` (`codigo_empleado` ASC),
  INDEX `empleados_sucursal_idx` (`sucursal_id` ASC),
  CONSTRAINT `empleados_persona_fk`
    FOREIGN KEY (`persona_id`) REFERENCES `weber`.`personas` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `empleados_sucursal_fk`
    FOREIGN KEY (`sucursal_id`) REFERENCES `weber`.`sucursales` (`id`) ON DELETE RESTRICT
) ENGINE = InnoDB DEFAULT CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = 'Empleados vinculados por sucursal';

-- -----------------------------------------------------
-- Tabla `weber`.`clientes`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `weber`.`clientes` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tipo_cliente` ENUM('Persona Natural', 'Empresa') NOT NULL DEFAULT 'Persona Natural',
  `persona_id` BIGINT UNSIGNED NULL DEFAULT NULL,
  `empresa_cliente_id` BIGINT UNSIGNED NULL DEFAULT NULL,
  `limite_credito` DECIMAL(15,2) UNSIGNED NOT NULL DEFAULT 0.00,
  `saldo_pendiente` DECIMAL(15,2) UNSIGNED NOT NULL DEFAULT 0.00,
  `estado` ENUM('Activo', 'Inactivo', 'Moroso') NOT NULL DEFAULT 'Activo',
  `creado_en` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `actualizado_en` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `eliminado_en` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  INDEX `clientes_persona_idx` (`persona_id` ASC),
  INDEX `clientes_empresa_idx` (`empresa_cliente_id` ASC),
  CONSTRAINT `clientes_persona_fk`
    FOREIGN KEY (`persona_id`) REFERENCES `weber`.`personas` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `clientes_empresa_fk`
    FOREIGN KEY (`empresa_cliente_id`) REFERENCES `weber`.`empresas` (`id`) ON DELETE RESTRICT
) ENGINE = InnoDB DEFAULT CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = 'Clientes naturales o corporativos';

-- -----------------------------------------------------
-- Tabla `weber`.`proveedores`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `weber`.`proveedores` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tipo_proveedor` ENUM('Persona Natural', 'Empresa') NOT NULL DEFAULT 'Empresa',
  `persona_id` BIGINT UNSIGNED NULL DEFAULT NULL,
  `empresa_proveedor_id` BIGINT UNSIGNED NULL DEFAULT NULL,
  `contacto_nombre` VARCHAR(100) NULL DEFAULT NULL,
  `contacto_telefono` VARCHAR(20) NULL DEFAULT NULL,
  `plazo_pago_dias` INT UNSIGNED NOT NULL DEFAULT 30,
  `estado` ENUM('Activo', 'Inactivo') NOT NULL DEFAULT 'Activo',
  `creado_en` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `actualizado_en` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `eliminado_en` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  INDEX `proveedores_persona_idx` (`persona_id` ASC),
  INDEX `proveedores_empresa_idx` (`empresa_proveedor_id` ASC),
  CONSTRAINT `proveedores_persona_fk`
    FOREIGN KEY (`persona_id`) REFERENCES `weber`.`personas` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `proveedores_empresa_fk`
    FOREIGN KEY (`empresa_proveedor_id`) REFERENCES `weber`.`empresas` (`id`) ON DELETE RESTRICT
) ENGINE = InnoDB DEFAULT CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = 'Proveedores de productos y mercancías';

-- -----------------------------------------------------
-- Tabla `weber`.`categorias`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `weber`.`categorias` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `nombre` VARCHAR(100) NOT NULL,
  `descripcion` TEXT NULL DEFAULT NULL,
  `categoria_padre_id` BIGINT UNSIGNED NULL DEFAULT NULL,
  `foto_url` VARCHAR(500) NULL DEFAULT NULL,
  `estado` ENUM('Activo', 'Inactivo') NOT NULL DEFAULT 'Activo',
  `creado_en` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `actualizado_en` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `eliminado_en` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `categorias_nombre_padre_unique` (`nombre` ASC, `categoria_padre_id` ASC),
  INDEX `categorias_padre_idx` (`categoria_padre_id` ASC),
  CONSTRAINT `categorias_padre_foreign`
    FOREIGN KEY (`categoria_padre_id`) REFERENCES `weber`.`categorias` (`id`) ON DELETE SET NULL
) ENGINE = InnoDB DEFAULT CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = 'Categorías jerárquicas de productos';

-- -----------------------------------------------------
-- Tabla `weber`.`productos`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `weber`.`productos` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `codigo` VARCHAR(50) NOT NULL COMMENT 'SKU o código de barras único',
  `nombre` VARCHAR(150) NOT NULL,
  `descripcion` TEXT NULL DEFAULT NULL,
  `precio_base` DECIMAL(15,2) UNSIGNED NOT NULL DEFAULT 0.00 COMMENT 'Precio de costo base de referencia',
  `ganancia_sugerida` DECIMAL(5,2) UNSIGNED NOT NULL DEFAULT 50.00 COMMENT 'Porcentaje de ganancia sugerido (%)',
  `precio_sugerido` DECIMAL(15,2) UNSIGNED NOT NULL DEFAULT 0.00 COMMENT 'Precio de venta al público sugerido',
  `stock_minimo` DECIMAL(10,3) UNSIGNED NOT NULL DEFAULT 5.000 COMMENT 'Umbral de alerta de stock bajo',
  `stock_maximo` DECIMAL(10,3) UNSIGNED NULL DEFAULT NULL,
  `atributos` JSON NULL DEFAULT NULL COMMENT 'Color, tamaño, presentación',
  `estado` ENUM('Activo', 'Inactivo', 'Descontinuado') NOT NULL DEFAULT 'Activo',
  `creado_en` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `actualizado_en` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `eliminado_en` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `productos_codigo_unique` (`codigo` ASC),
  INDEX `productos_nombre_idx` (`nombre` ASC),
  INDEX `productos_estado_idx` (`estado` ASC),
  FULLTEXT INDEX `productos_busqueda_fulltext` (`nombre`, `descripcion`)
) ENGINE = InnoDB DEFAULT CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = 'Catálogo maestro de productos';

-- -----------------------------------------------------
-- Tabla `weber`.`producto_categoria` (N:M Categorías)
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `weber`.`producto_categoria` (
  `producto_id` BIGINT UNSIGNED NOT NULL,
  `categoria_id` BIGINT UNSIGNED NOT NULL,
  `es_principal` TINYINT(1) NOT NULL DEFAULT 0,
  `orden` TINYINT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`producto_id`, `categoria_id`),
  INDEX `producto_categoria_categoria_idx` (`categoria_id` ASC),
  CONSTRAINT `producto_categoria_producto_fk`
    FOREIGN KEY (`producto_id`) REFERENCES `weber`.`productos` (`id`) ON DELETE CASCADE,
  CONSTRAINT `producto_categoria_categoria_fk`
    FOREIGN KEY (`categoria_id`) REFERENCES `weber`.`categorias` (`id`) ON DELETE CASCADE
) ENGINE = InnoDB DEFAULT CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = 'Relación N:M de productos y categorías con categoría principal';

-- -----------------------------------------------------
-- Tabla `weber`.`archivos` (Gestor Documental y Multimedia)
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `weber`.`archivos` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `uuid` CHAR(36) NOT NULL,
  `model` VARCHAR(60) NOT NULL COMMENT 'Entidad asociada: productos, categorias, personas',
  `model_id` BIGINT UNSIGNED NOT NULL,
  `nombre_original` VARCHAR(255) NOT NULL,
  `nombre_archivo` VARCHAR(255) NOT NULL,
  `ruta_archivo` VARCHAR(500) NOT NULL,
  `extension` VARCHAR(10) NOT NULL,
  `tipo_archivo` ENUM('imagen', 'documento', 'video', 'otro') NOT NULL DEFAULT 'imagen',
  `metadatos` JSON NULL DEFAULT NULL,
  `estado` ENUM('activo', 'archivado', 'eliminado') NOT NULL DEFAULT 'activo',
  `creado_en` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `actualizado_en` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `eliminado_en` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `archivos_uuid_unique` (`uuid` ASC),
  INDEX `archivos_model_idx` (`model` ASC, `model_id` ASC)
) ENGINE = InnoDB DEFAULT CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = 'Gestor de archivos y fotografías polimórficas';

-- -----------------------------------------------------
-- Tabla `weber`.`transacciones` (Cabecera Comercial: Venta / Compra)
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `weber`.`transacciones` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `sucursal_id` BIGINT UNSIGNED NOT NULL,
  `numero_factura` VARCHAR(80) NOT NULL,
  `tipo_transaccion` ENUM('Venta', 'Compra') NOT NULL,
  `cliente_id` BIGINT UNSIGNED NULL DEFAULT NULL COMMENT 'Aplica en Ventas',
  `proveedor_id` BIGINT UNSIGNED NULL DEFAULT NULL COMMENT 'Aplica en Compras',
  `empleado_id` BIGINT UNSIGNED NOT NULL COMMENT 'Empleado que expide o registra',
  `fecha` DATETIME NOT NULL,
  `valor_base` DECIMAL(15,2) UNSIGNED NOT NULL DEFAULT 0.00,
  `descuento` DECIMAL(15,2) UNSIGNED NOT NULL DEFAULT 0.00,
  `impuestos` DECIMAL(15,2) UNSIGNED NOT NULL DEFAULT 0.00,
  `total` DECIMAL(15,2) NOT NULL DEFAULT 0.00,
  `metodo_pago` ENUM('Efectivo', 'Tarjeta_Debito', 'Tarjeta_Credito', 'Transferencia', 'Credito', 'Mixto') NOT NULL DEFAULT 'Efectivo',
  `estado` ENUM('Borrador', 'Finalizada', 'Anulada') NOT NULL DEFAULT 'Finalizada',
  `observaciones` TEXT NULL DEFAULT NULL,
  `creado_en` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `actualizado_en` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `eliminado_en` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `transacciones_numero_sucursal_unique` (`sucursal_id` ASC, `tipo_transaccion` ASC, `numero_factura` ASC),
  INDEX `transacciones_fecha_idx` (`fecha` ASC),
  INDEX `transacciones_cliente_idx` (`cliente_id` ASC),
  INDEX `transacciones_proveedor_idx` (`proveedor_id` ASC),
  INDEX `transacciones_empleado_idx` (`empleado_id` ASC),
  CONSTRAINT `transacciones_sucursal_fk`
    FOREIGN KEY (`sucursal_id`) REFERENCES `weber`.`sucursales` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `transacciones_cliente_fk`
    FOREIGN KEY (`cliente_id`) REFERENCES `weber`.`clientes` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `transacciones_proveedor_fk`
    FOREIGN KEY (`proveedor_id`) REFERENCES `weber`.`proveedores` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `transacciones_empleado_fk`
    FOREIGN KEY (`empleado_id`) REFERENCES `weber`.`empleados` (`id`) ON DELETE RESTRICT
) ENGINE = InnoDB DEFAULT CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = 'Encabezado de transacciones de compra y venta';

-- -----------------------------------------------------
-- Tabla `weber`.`detalles_transaccion` (Líneas de Factura)
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `weber`.`detalles_transaccion` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `transaccion_id` BIGINT UNSIGNED NOT NULL,
  `producto_id` BIGINT UNSIGNED NOT NULL,
  `cantidad` DECIMAL(10,3) UNSIGNED NOT NULL,
  `precio_unitario` DECIMAL(15,2) UNSIGNED NOT NULL COMMENT 'Precio de venta o costo de compra pactado',
  `descuento` DECIMAL(15,2) UNSIGNED NOT NULL DEFAULT 0.00,
  `subtotal` DECIMAL(15,2) UNSIGNED NOT NULL,
  `observaciones` VARCHAR(255) NULL DEFAULT NULL,
  `creado_en` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `detalles_transaccion_fk_idx` (`transaccion_id` ASC),
  INDEX `detalles_producto_fk_idx` (`producto_id` ASC),
  CONSTRAINT `detalles_transaccion_fk`
    FOREIGN KEY (`transaccion_id`) REFERENCES `weber`.`transacciones` (`id`) ON DELETE CASCADE,
  CONSTRAINT `detalles_producto_fk`
    FOREIGN KEY (`producto_id`) REFERENCES `weber`.`productos` (`id`) ON DELETE RESTRICT
) ENGINE = InnoDB DEFAULT CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = 'Detalle de ítems de compras y ventas';

-- -----------------------------------------------------
-- Tabla `weber`.`lotes_inventario` (Control FIFO por Lote)
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `weber`.`lotes_inventario` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `sucursal_id` BIGINT UNSIGNED NOT NULL,
  `producto_id` BIGINT UNSIGNED NOT NULL,
  `detalle_transaccion_compra_id` BIGINT UNSIGNED NULL DEFAULT NULL COMMENT 'Detalle de la compra que originó el lote',
  `numero_lote` VARCHAR(50) NOT NULL,
  `fecha_fabricacion` DATE NULL DEFAULT NULL,
  `fecha_vencimiento` DATE NULL DEFAULT NULL,
  `costo_unitario` DECIMAL(15,4) UNSIGNED NOT NULL COMMENT 'Costo de compra del lote',
  `porcentaje_ganancia` DECIMAL(5,2) UNSIGNED NOT NULL DEFAULT 50.00,
  `precio_venta_calculado` DECIMAL(15,2) UNSIGNED NOT NULL,
  `cantidad_inicial` DECIMAL(10,3) UNSIGNED NOT NULL,
  `cantidad_disponible` DECIMAL(10,3) UNSIGNED NOT NULL COMMENT 'Stock remanente del lote',
  `esta_agotado` TINYINT(1) NOT NULL DEFAULT 0,
  `estado` ENUM('Disponible', 'Cuarentena', 'Vencido', 'Agotado') NOT NULL DEFAULT 'Disponible',
  `creado_en` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `actualizado_en` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `lotes_sucursal_producto_idx` (`sucursal_id` ASC, `producto_id` ASC),
  INDEX `lotes_fifo_idx` (`sucursal_id` ASC, `producto_id` ASC, `fecha_vencimiento` ASC, `creado_en` ASC),
  INDEX `lotes_disponible_idx` (`cantidad_disponible` ASC, `esta_agotado` ASC),
  CONSTRAINT `lotes_sucursal_fk`
    FOREIGN KEY (`sucursal_id`) REFERENCES `weber`.`sucursales` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `lotes_producto_fk`
    FOREIGN KEY (`producto_id`) REFERENCES `weber`.`productos` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `lotes_detalle_compra_fk`
    FOREIGN KEY (`detalle_transaccion_compra_id`) REFERENCES `weber`.`detalles_transaccion` (`id`) ON DELETE SET NULL
) ENGINE = InnoDB DEFAULT CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = 'Lotes de inventario para valuación y rotación FIFO';

-- -----------------------------------------------------
-- Tabla `weber`.`movimientos_inventario` (Kardex Físico y Valorado)
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `weber`.`movimientos_inventario` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `sucursal_id` BIGINT UNSIGNED NOT NULL,
  `producto_id` BIGINT UNSIGNED NOT NULL,
  `lote_id` BIGINT UNSIGNED NOT NULL,
  `detalle_transaccion_id` BIGINT UNSIGNED NULL DEFAULT NULL,
  `tipo_movimiento` ENUM('Entrada_Compra', 'Salida_Venta', 'Devolucion_Cliente', 'Devolucion_Proveedor', 'Ajuste_Inventario') NOT NULL,
  `cantidad` DECIMAL(10,3) UNSIGNED NOT NULL,
  `costo_unitario` DECIMAL(15,4) UNSIGNED NOT NULL,
  `precio_unitario` DECIMAL(15,2) UNSIGNED NOT NULL DEFAULT 0.00,
  `fecha` DATETIME NOT NULL,
  `observaciones` VARCHAR(255) NULL DEFAULT NULL,
  `creado_en` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `movimientos_sucursal_producto_idx` (`sucursal_id` ASC, `producto_id` ASC, `fecha` ASC),
  INDEX `movimientos_lote_idx` (`lote_id` ASC),
  CONSTRAINT `movimientos_sucursal_fk`
    FOREIGN KEY (`sucursal_id`) REFERENCES `weber`.`sucursales` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `movimientos_producto_fk`
    FOREIGN KEY (`producto_id`) REFERENCES `weber`.`productos` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `movimientos_lote_fk`
    FOREIGN KEY (`lote_id`) REFERENCES `weber`.`lotes_inventario` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `movimientos_detalle_transaccion_fk`
    FOREIGN KEY (`detalle_transaccion_id`) REFERENCES `weber`.`detalles_transaccion` (`id`) ON DELETE SET NULL
) ENGINE = InnoDB DEFAULT CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = 'Kardex de movimientos de inventario por lote';

-- -----------------------------------------------------
-- Tabla `weber`.`devoluciones` (Cabecera de Devolución)
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `weber`.`devoluciones` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `sucursal_id` BIGINT UNSIGNED NOT NULL,
  `transaccion_id` BIGINT UNSIGNED NOT NULL COMMENT 'Factura origen que se afecta',
  `numero` VARCHAR(50) NOT NULL COMMENT 'Número consecutivo de la devolución',
  `fecha` DATETIME NOT NULL,
  `tipo_devolucion` ENUM('Venta', 'Compra') NOT NULL,
  `monto_total` DECIMAL(15,2) UNSIGNED NOT NULL DEFAULT 0.00,
  `estado` ENUM('Pendiente', 'Aprobada', 'Rechazada') NOT NULL DEFAULT 'Aprobada',
  `observaciones` TEXT NOT NULL,
  `empleado_id` BIGINT UNSIGNED NOT NULL COMMENT 'Empleado que gestiona la devolución',
  `creado_en` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `actualizado_en` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `eliminado_en` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `devoluciones_numero_sucursal_unique` (`sucursal_id` ASC, `numero` ASC),
  INDEX `devoluciones_transaccion_idx` (`transaccion_id` ASC),
  CONSTRAINT `devoluciones_sucursal_fk`
    FOREIGN KEY (`sucursal_id`) REFERENCES `weber`.`sucursales` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `devoluciones_transaccion_fk`
    FOREIGN KEY (`transaccion_id`) REFERENCES `weber`.`transacciones` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `devoluciones_empleado_fk`
    FOREIGN KEY (`empleado_id`) REFERENCES `weber`.`empleados` (`id`) ON DELETE RESTRICT
) ENGINE = InnoDB DEFAULT CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = 'Encabezado de devoluciones de clientes y proveedores';

-- -----------------------------------------------------
-- Tabla `weber`.`detalles_devolucion` (Ítems Devueltos)
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `weber`.`detalles_devolucion` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `devolucion_id` BIGINT UNSIGNED NOT NULL,
  `detalle_transaccion_id` BIGINT UNSIGNED NOT NULL,
  `producto_id` BIGINT UNSIGNED NOT NULL,
  `lote_id` BIGINT UNSIGNED NULL DEFAULT NULL,
  `cantidad_devuelta` DECIMAL(10,3) UNSIGNED NOT NULL,
  `monto_reintegrado` DECIMAL(15,2) UNSIGNED NOT NULL,
  `motivo` ENUM('Producto_Defectuoso', 'Error_Cantidad', 'Error_Producto', 'Cliente_No_Satisfecho', 'Vencimiento', 'Otro') NOT NULL,
  `retorna_a_inventario` TINYINT(1) NOT NULL DEFAULT 1 COMMENT '1 si el producto devuelto se reincorpora al stock',
  `observaciones` VARCHAR(255) NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  INDEX `detalles_devolucion_fk_idx` (`devolucion_id` ASC),
  CONSTRAINT `detalles_devolucion_fk`
    FOREIGN KEY (`devolucion_id`) REFERENCES `weber`.`devoluciones` (`id`) ON DELETE CASCADE,
  CONSTRAINT `detalles_devolucion_detalle_trans_fk`
    FOREIGN KEY (`detalle_transaccion_id`) REFERENCES `weber`.`detalles_transaccion` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `detalles_devolucion_producto_fk`
    FOREIGN KEY (`producto_id`) REFERENCES `weber`.`productos` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `detalles_devolucion_lote_fk`
    FOREIGN KEY (`lote_id`) REFERENCES `weber`.`lotes_inventario` (`id`) ON DELETE SET NULL
) ENGINE = InnoDB DEFAULT CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = 'Ítems detallados en una devolución';

-- =============================================================================
-- Vistas Analíticas de Inventario y Rentabilidad
-- =============================================================================

-- -----------------------------------------------------
-- Vista: `v_disponibilidad_fifo`
-- -----------------------------------------------------
CREATE OR REPLACE VIEW `weber`.`v_disponibilidad_fifo` AS
SELECT 
    l.`id` AS `lote_id`,
    l.`sucursal_id`,
    s.`nombre` AS `nombre_sucursal`,
    p.`id` AS `producto_id`,
    p.`codigo`,
    p.`nombre` AS `nombre_producto`,
    l.`numero_lote`,
    l.`cantidad_disponible`,
    l.`costo_unitario`,
    l.`precio_venta_calculado`,
    l.`fecha_vencimiento`,
    l.`creado_en` AS `fecha_ingreso`,
    CASE 
        WHEN l.`fecha_vencimiento` IS NOT NULL THEN DATEDIFF(l.`fecha_vencimiento`, CURDATE()) 
        ELSE NULL 
    END AS `dias_para_vencer`,
    CASE 
        WHEN l.`fecha_vencimiento` IS NOT NULL AND DATEDIFF(l.`fecha_vencimiento`, CURDATE()) <= 0 THEN 'Vencido'
        WHEN l.`fecha_vencimiento` IS NOT NULL AND DATEDIFF(l.`fecha_vencimiento`, CURDATE()) <= 30 THEN 'Próximo a Vencer'
        ELSE 'Normal'
    END AS `estado_vencimiento`
FROM `weber`.`lotes_inventario` l
INNER JOIN `weber`.`productos` p ON l.`producto_id` = p.`id`
INNER JOIN `weber`.`sucursales` s ON l.`sucursal_id` = s.`id`
WHERE l.`cantidad_disponible` > 0 
  AND l.`esta_agotado` = 0 
  AND l.`estado` = 'Disponible'
  AND p.`estado` = 'Activo'
  AND s.`estado` = 'Activo'
ORDER BY l.`sucursal_id`, l.`producto_id`, l.`fecha_vencimiento` ASC, l.`creado_en` ASC;

-- -----------------------------------------------------
-- Vista: `v_inventario_sucursal`
-- -----------------------------------------------------
CREATE OR REPLACE VIEW `weber`.`v_inventario_sucursal` AS
SELECT 
    s.`id` AS `sucursal_id`,
    s.`nombre` AS `nombre_sucursal`,
    p.`id` AS `producto_id`,
    p.`codigo`,
    p.`nombre` AS `nombre_producto`,
    p.`stock_minimo`,
    p.`stock_maximo`,
    COALESCE(SUM(l.`cantidad_disponible`), 0) AS `stock_actual`,
    CASE 
        WHEN COALESCE(SUM(l.`cantidad_disponible`), 0) = 0 THEN 'Agotado'
        WHEN COALESCE(SUM(l.`cantidad_disponible`), 0) <= p.`stock_minimo` THEN 'Stock Bajo'
        ELSE 'Normal'
    END AS `estado_stock`,
    COUNT(DISTINCT CASE WHEN l.`cantidad_disponible` > 0 THEN l.`id` END) AS `lotes_activos`
FROM `weber`.`sucursales` s
CROSS JOIN `weber`.`productos` p
LEFT JOIN `weber`.`lotes_inventario` l ON s.`id` = l.`sucursal_id` AND p.`id` = l.`producto_id` AND l.`esta_agotado` = 0
WHERE s.`estado` = 'Activo' AND p.`estado` = 'Activo'
GROUP BY s.`id`, s.`nombre`, p.`id`, p.`codigo`, p.`nombre`, p.`stock_minimo`, p.`stock_maximo`
ORDER BY s.`nombre`, p.`nombre`;

-- -----------------------------------------------------
-- Vista: `v_rentabilidad_productos`
-- -----------------------------------------------------
CREATE OR REPLACE VIEW `weber`.`v_rentabilidad_productos` AS
SELECT 
    s.`id` AS `sucursal_id`,
    s.`nombre` AS `nombre_sucursal`,
    p.`id` AS `producto_id`,
    p.`codigo`,
    p.`nombre` AS `nombre_producto`,
    COUNT(DISTINCT t.`id`) AS `total_transacciones_venta`,
    COALESCE(SUM(dt.`cantidad`), 0) AS `unidades_vendidas`,
    COALESCE(SUM(dt.`subtotal`), 0) AS `ingresos_totales`,
    COALESCE(SUM(m.`cantidad` * m.`costo_unitario`), 0) AS `costos_totales`,
    COALESCE(SUM(dt.`subtotal`), 0) - COALESCE(SUM(m.`cantidad` * m.`costo_unitario`), 0) AS `utilidad_bruta`
FROM `weber`.`transacciones` t
INNER JOIN `weber`.`sucursales` s ON t.`sucursal_id` = s.`id`
INNER JOIN `weber`.`detalles_transaccion` dt ON t.`id` = dt.`transaccion_id`
INNER JOIN `weber`.`productos` p ON dt.`producto_id` = p.`id`
LEFT JOIN `weber`.`movimientos_inventario` m ON dt.`id` = m.`detalle_transaccion_id` AND m.`tipo_movimiento` = 'Salida_Venta'
WHERE t.`tipo_transaccion` = 'Venta' AND t.`estado` = 'Finalizada'
GROUP BY s.`id`, s.`nombre`, p.`id`, p.`codigo`, p.`nombre`;

-- -----------------------------------------------------
-- Vista: `v_todas_transacciones`
-- -----------------------------------------------------
CREATE OR REPLACE VIEW `weber`.`v_todas_transacciones` AS
SELECT 
    t.`id`,
    t.`numero_factura`,
    t.`tipo_transaccion`,
    t.`sucursal_id`,
    s.`nombre` AS `nombre_sucursal`,
    t.`fecha`,
    t.`total`,
    t.`metodo_pago`,
    t.`estado`,
    CONCAT(e_per.`nombres`, ' ', e_per.`apellidos`) AS `empleado_nombre`,
    CASE 
        WHEN t.`tipo_transaccion` = 'Venta' AND cli.`tipo_cliente` = 'Persona Natural' THEN CONCAT(c_per.`nombres`, ' ', c_per.`apellidos`)
        WHEN t.`tipo_transaccion` = 'Venta' AND cli.`tipo_cliente` = 'Empresa' THEN c_emp.`nombre`
        WHEN t.`tipo_transaccion` = 'Compra' AND prv.`tipo_proveedor` = 'Persona Natural' THEN CONCAT(p_per.`nombres`, ' ', p_per.`apellidos`)
        WHEN t.`tipo_transaccion` = 'Compra' AND prv.`tipo_proveedor` = 'Empresa' THEN p_emp.`nombre`
        ELSE 'N/A'
    END AS `tercero_nombre`
FROM `weber`.`transacciones` t
INNER JOIN `weber`.`sucursales` s ON t.`sucursal_id` = s.`id`
INNER JOIN `weber`.`empleados` e ON t.`empleado_id` = e.`id`
INNER JOIN `weber`.`personas` e_per ON e.`persona_id` = e_per.`id`
LEFT JOIN `weber`.`clientes` cli ON t.`cliente_id` = cli.`id`
LEFT JOIN `weber`.`personas` c_per ON cli.`persona_id` = c_per.`id`
LEFT JOIN `weber`.`empresas` c_emp ON cli.`empresa_cliente_id` = c_emp.`id`
LEFT JOIN `weber`.`proveedores` prv ON t.`proveedor_id` = prv.`id`
LEFT JOIN `weber`.`personas` p_per ON prv.`persona_id` = p_per.`id`
LEFT JOIN `weber`.`empresas` p_emp ON prv.`empresa_proveedor_id` = p_emp.`id`
ORDER BY t.`fecha` DESC;

SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;
