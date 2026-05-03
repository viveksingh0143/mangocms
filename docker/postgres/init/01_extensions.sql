-- docker/postgres/init/01_extensions.sql
-- Runs automatically on first `docker compose up` when the volume is empty.
-- Safe to add more .sql files here — they run in filename order.

-- Useful extensions for future use
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";   -- UUID generation
CREATE EXTENSION IF NOT EXISTS "pg_trgm";     -- trigram similarity (fuzzy search)
CREATE EXTENSION IF NOT EXISTS "citext";      -- case-insensitive text type