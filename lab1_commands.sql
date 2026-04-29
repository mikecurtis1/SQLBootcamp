-- SQL Lab 1: Command Summary
--
-- This file contains the minimal SQL statements used in Lab 1,
-- presented without system-level exploration or explanatory output.
--
-- The purpose is to provide a concise, runnable sequence of commands
-- that mirrors the full lab workflow:
--   1. Create a database and table structure (DDL)
--   2. Insert and retrieve data (DML / CRUD)
--   3. Remove all created objects (teardown)
--
-- Notes:
-- * These commands assume execution as the default 'postgres' user.
-- * Database connection changes (e.g., \c mydb) are not included here.
-- * This file is intended as a companion to the full Markdown lab,
--   not a standalone teaching document.

------------------------------------------------------------
-- CREATE: Define database and table structure
------------------------------------------------------------

-- Create a new database named 'mydb'
CREATE DATABASE mydb;

-- Create an empty table (no columns defined yet)
CREATE TABLE my_table ();

-- Add a column named 'field_1' of type TEXT
ALTER TABLE my_table ADD COLUMN field_1 text;

------------------------------------------------------------
-- INSERT: Add data
------------------------------------------------------------

-- Insert a single row with value 'hello'
INSERT INTO my_table (field_1) VALUES ('hello');

------------------------------------------------------------
-- READ: Retrieve data
------------------------------------------------------------

-- Select all values from the column
SELECT field_1 FROM my_table;

------------------------------------------------------------
-- DELETE (teardown): Remove created objects
------------------------------------------------------------

-- Drop the table (removes all data and structure)
DROP TABLE my_table;

-- Drop the database (must not be connected to it when executed)
DROP DATABASE mydb;
