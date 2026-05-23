-- =====================================================
-- DoctorNex — Inicialización de bases de datos
-- Este script se ejecuta automáticamente la primera
-- vez que se crea el contenedor de MySQL.
--
-- Para agregar un nuevo microservicio:
--   1. Agrega un CREATE DATABASE aquí
--   2. Agrega el GRANT correspondiente
-- =====================================================

-- Auth Service
-- (doctor_nex_auth ya fue creada por MYSQL_DATABASE en docker-compose)
GRANT ALL PRIVILEGES ON doctor_nex_auth.* TO 'doctornex'@'%';

-- Core Service
CREATE DATABASE IF NOT EXISTS doctor_nex_core
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

GRANT ALL PRIVILEGES ON doctor_nex_core.* TO 'doctornex'@'%';

FLUSH PRIVILEGES;
