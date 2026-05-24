# SQL Lab 2 — Schema Design, Procedural SQL, and Transactions

## PostgreSQL

> [https://www.postgresql.org/docs/current/index.html](https://www.postgresql.org/docs/current/index.html)

This lab builds directly on Lab 1, where we constructed a PostgreSQL environment from a completely empty state and explored how system layers (Linux, database engine, SQL interface) interact.

In Lab 1, the focus was visibility: understanding what the system *is* and how SQL commands map onto real processes, files, and database objects.

In Lab 2, we shift from observation to design and controlled behavior. Instead of working with isolated SQL statements, we begin constructing a small but realistic schema. This introduces structured data modeling, procedural automation inside the database, and transaction control for managing state safely.

To support this transition, the lab is divided into two connected parts:

* **Part I — SQL Command Templates (Reference Layer)**
  A compact, reduced-form overview of the most important SQL patterns used in this lab.

* **Part II — Implementation Demo (half_shell Schema Build)**
  A worked example that applies these patterns to build a minimal production-style database schema.

---

# Part I — SQL Command Templates (Reference Layer)

This section is not a full replacement for PostgreSQL documentation. Instead, it is a simplified “working grammar” of SQL used throughout this lab.

The goal is to provide quick mental models of how each command behaves before seeing it used in a real schema.

---

## DDL — Data Definition Language (Schema Structure)

DDL defines the structure of a database: what exists before any data is inserted.

> [https://www.postgresql.org/docs/current/ddl.html](https://www.postgresql.org/docs/current/ddl.html)

### CREATE DATABASE

```sql
CREATE DATABASE name;
```

Creates a new database instance.

Optional modifiers include:

* `ENCODING`
* `LC_COLLATE`
* `LC_CTYPE`
* `CONNECTION LIMIT`

---

### CREATE TABLE

```sql
CREATE TABLE name (
    column_name data_type [constraints]
);
```

Common constraints:

* `PRIMARY KEY`
* `FOREIGN KEY`
* `UNIQUE`
* `NOT NULL`
* `DEFAULT`
* `COLLATE`

---

### ALTER TABLE

```sql
ALTER TABLE name ADD COLUMN column_name data_type;
```

Used to modify schema after creation.

Common modifiers:

* `IF NOT EXISTS`
* `DEFAULT expression`
* `NOT NULL`
* `UNIQUE`

---

### CREATE INDEX

```sql
CREATE INDEX name ON table_name (column_name);
```

Creates an index to improve query performance.

---

### DROP / TRUNCATE / RENAME

```sql
DROP TABLE name;
DROP DATABASE name;
TRUNCATE TABLE name;
ALTER TABLE name RENAME TO new_name;
```

* `DROP` removes structure entirely
* `TRUNCATE` removes data but keeps structure
* `RENAME` changes object identity

---

### VIEW

```sql
CREATE VIEW name AS
SELECT ...;
```

A view is a stored query that behaves like a virtual table.

---

## DML — Data Manipulation Language (CRUD)

DML operates on data inside an existing schema.

> [https://www.postgresql.org/docs/current/dml.html](https://www.postgresql.org/docs/current/dml.html)

### CREATE (INSERT)

```sql
INSERT INTO table_name (column_name) VALUES (expression);
```

---

### READ (SELECT)

```sql
SELECT expression FROM table_name;
```

Common clauses:

* `WHERE`
* `ORDER BY`
* `GROUP BY`
* `HAVING`
* `LIMIT`
* `OFFSET`
* `JOIN`
* `AS` (alias)
* `DISTINCT`

Example:

```sql
SELECT 2 + 2;
SELECT 'foo';
```

---

### UPDATE

```sql
UPDATE table_name
SET column_name = expression
WHERE condition;
```

---

### DELETE

```sql
DELETE FROM table_name
WHERE condition;
```

---

## Transaction Control (TCL)

Transactions manage changes as atomic units of work.

> [https://www.postgresql.org/docs/current/transaction-iso.html](https://www.postgresql.org/docs/current/transaction-iso.html)

```sql
BEGIN;

-- operations

COMMIT;

-- or

ROLLBACK;
```

* `BEGIN` starts a transaction
* `COMMIT` permanently applies changes
* `ROLLBACK` discards changes

---

## Procedural SQL — Database Logic Layer

PostgreSQL extends SQL with procedural capabilities that allow logic to run inside the database itself.

> [https://www.postgresql.org/docs/current/plpgsql.html](https://www.postgresql.org/docs/current/plpgsql.html)

These constructs allow behavior beyond simple CRUD.

---

### FUNCTION

```sql
CREATE FUNCTION name()
RETURNS return_type
LANGUAGE plpgsql
AS $$
BEGIN
    -- logic
END;
$$;
```

Used for reusable computation or transformation logic.

---

### PROCEDURE

```sql
CREATE PROCEDURE name()
LANGUAGE plpgsql
AS $$
BEGIN
    -- logic
END;
$$;

CALL name();
```

Used for explicit execution of multi-step operations.

---

### TRIGGER

```sql
CREATE TRIGGER name
BEFORE | AFTER INSERT | UPDATE | DELETE
ON table_name
FOR EACH ROW
EXECUTE FUNCTION function_name();
```

Triggers execute automatically in response to table events.

---

# Part II — Implementation Demo: Building the `half_shell` Schema

In this section, we apply the earlier command templates to construct a small but realistic PostgreSQL database named `half_shell`.

Unlike Lab 1, which focused on system visibility and environmental exploration, this lab focuses on intentional database design and controlled data interaction. The goal is not simply to create tables, but to demonstrate how schema definition, querying, transactions, views, and automated behavior work together within a relational system.

The implementation sequence follows five conceptual layers:

1. **SCHEMA** — defining structure
2. **QUERY** — interacting with data
3. **VIEW** — reusable query abstraction
4. **TRANSACTION** — controlled state changes
5. **BEHAVIOR** — automated database-side logic

---

# SCHEMA — Defining Structure

The schema layer establishes the structural foundation of the database.

This includes:

* creating the database
* defining tables
* declaring constraints
* defining relationships
* creating indexes

At this stage we are defining what exists, but not yet working with data itself.

---

## Step 1 — Create the database

```sql
CREATE DATABASE half_shell
WITH ENCODING = 'UTF8'
LC_COLLATE = 'en_US.utf8'
LC_CTYPE = 'en_US.utf8';
```

This creates a clean PostgreSQL database environment with explicit locale and encoding settings.

Connect to the new `half_shell` database.

```psql
\c half_shell
```
```text
You are now connected to database "half_shell" as user "postgres".
```

---

## Step 2 — Create supporting lookup table

```sql
CREATE TABLE IF NOT EXISTS language (
    iso639_3 varchar(3) PRIMARY KEY,
    language_name varchar(64) NOT NULL
);
```

This table stores language metadata separately from the main collection records.

Separating reusable lookup data into its own table is a common relational design pattern and allows records to reference standardized values instead of duplicating text repeatedly.

---

## Step 3 — Create the core collection table

```sql
CREATE TABLE IF NOT EXISTS collection (
    id SERIAL PRIMARY KEY,
    identifier varchar(8) NOT NULL UNIQUE,
    created timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    modified timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status smallint NOT NULL DEFAULT 1,
    author varchar(255) NOT NULL,
    year varchar(4) NOT NULL,
    title text NOT NULL,
    description text NOT NULL,
    isbn varchar(13) NOT NULL,
    language_iso639_3 varchar(3) NOT NULL,
    root_set int NOT NULL DEFAULT 0,
    sub_set int NOT NULL DEFAULT 0,
    CONSTRAINT fk_language
        FOREIGN KEY (language_iso639_3)
        REFERENCES language(iso639_3)
);
```

This table introduces several important schema concepts:

* **Primary key (`id`)** — internal row identity
* **Unique business identifier (`identifier`)** — externally meaningful uniqueness
* **Default values** — automatic initialization
* **Foreign key relationship** — relational integrity between tables
* **Structured metadata fields** — author, ISBN, language, status

This represents a simplified but realistic production-style relational schema.

---

## Step 4 — Create indexes

```sql
CREATE INDEX idx_collection_isbn
ON collection(isbn);
```

This index improves lookup performance for ISBN-based searches.

---

```sql
CREATE INDEX idx_collection_description_ft
ON collection
USING GIN (to_tsvector('english', description));
```

This creates a PostgreSQL full-text search index on the `description` column using a GIN index structure.

List indexes.

```psql
\di
```

```text
                           List of relations
 Schema |             Name              | Type  |  Owner   |   Table
--------+-------------------------------+-------+----------+------------
 public | collection_identifier_key     | index | postgres | collection
 public | collection_pkey               | index | postgres | collection
 public | idx_collection_description_ft | index | postgres | collection
 public | idx_collection_isbn           | index | postgres | collection
 public | language_pkey                 | index | postgres | language
(5 rows)
```

---

# QUERY — Reading and Manipulating Data

With the schema defined, we can begin inserting and retrieving data.

This section introduces the core CRUD-style interaction pattern:

* inserting rows
* selecting rows
* filtering rows
* joining related tables

The focus here is not advanced SQL syntax, but understanding how data moves through the relational system.

---

## Step 5 — Insert reference data

```sql
INSERT INTO language (iso639_3, language_name)
VALUES
('eng', 'English'),
('spa', 'Spanish'),
('jpn', 'Japanese');
```

---

## Step 6 — Insert collection records

```sql
INSERT INTO collection (
    identifier,
    author,
    year,
    title,
    description,
    isbn,
    language_iso639_3
)
VALUES
(
    'BK000001',
    'Frank Herbert',
    '1965',
    'Dune',
    'Science fiction novel set on Arrakis.',
    '9780441172719',
    'eng'
),
(
    'BK000002',
    'Miguel de Cervantes',
    '1605',
    'Don Quixote',
    'Spanish novel about a wandering knight.',
    '9780060934347',
    'spa'
);
```

---

## Step 7 — Basic SELECT query

```sql
SELECT title, author
FROM collection;
```

This retrieves selected columns from all rows in the table.

```text
    title    |       author
-------------+---------------------
 Dune        | Frank Herbert
 Don Quixote | Miguel de Cervantes
(2 rows)
```

---

## Step 8 — SELECT with WHERE filtering

```sql
SELECT title, year
FROM collection
WHERE year = '1965';
```

The `WHERE` clause filters rows based on a condition.

This shifts SQL from whole-table operations to targeted row selection.

```text
 title | year
-------+------
 Dune  | 1965
(1 row)
```

---

## Step 9 — Basic JOIN query

Relational databases are designed to separate related information into multiple tables. Queries can then reconnect that information dynamically using relationships defined through foreign keys.

```psql
\d language
```

```text
                        Table "public.language"
    Column     |         Type          | Collation | Nullable | Default
---------------+-----------------------+-----------+----------+---------
 iso639_3      | character varying(3)  |           | not null |
 language_name | character varying(64) |           | not null |
Indexes:
    "language_pkey" PRIMARY KEY, btree (iso639_3)
Referenced by:
    TABLE "collection" CONSTRAINT "fk_language" FOREIGN KEY (language_iso639_3) REFERENCES language(iso639_3)
```
> Note the `language` table column `iso639_3` and its relation to "foreign" (another table) column `language_iso639_3` in table `collection`.

Review separate tables.

```sql
SELECT title,author,language_iso639_3 FROM collection;
```
```text
    title    |       author        | language_iso639_3
-------------+---------------------+-------------------
 Dune        | Frank Herbert       | eng
 Don Quixote | Miguel de Cervantes | spa
(2 rows)
```

```sql
SELECT iso639_3,language_name FROM language;
```
```text
 iso639_3 | language_name
----------+---------------
 eng      | English
 spa      | Spanish
 jpn      | Japanese
(3 rows)
```

> Note the `collection` table has only a language code but not the full name of languages while the full language name is in the separate `languages` table. If we join the two tables, we can select collection data and language data.

```sql
SELECT
    c.title,
    c.author,
    l.language_name
FROM collection c
JOIN language l
ON c.language_iso639_3 = l.iso639_3;
```

This query combines rows from two related tables using the foreign key relationship established earlier.

Relational databases derive much of their power from this ability to connect structured data across tables.

```text
    title    |       author        | language_name
-------------+---------------------+---------------
 Dune        | Frank Herbert       | English
 Don Quixote | Miguel de Cervantes | Spanish
(2 rows)
```

> Note the _alias_ `c` in clause `FROM collection c`. This is a convenient short hand meaning `collection` can also be referenced by `c` as in `c.title` rather than the explicit name `collection.title`. Aliases shorten queries and make them more readable.

---

# VIEW — Named Query Abstraction

Views allow queries themselves to become reusable database objects.

A view does not store data independently. Instead, it presents the results of a query as a virtual table.

Views are commonly used to:

* simplify repeated queries
* restrict visible columns
* expose filtered subsets of data
* provide stable interfaces for applications

---

## Step 10 — Create a simplified public view

```sql
CREATE VIEW public_collection_view AS
SELECT
    identifier,
    title,
    author,
    year
FROM collection;
```

This view exposes only a simplified subset of collection data.

Applications or users can query the view without needing direct access to the full underlying table structure.

---

## Step 11 — Create an active-records view

```sql
CREATE VIEW active_collection_view AS
SELECT
    identifier,
    title,
    author,
    status
FROM collection
WHERE status = 1;
```

This view permanently embeds filtering logic into the database layer.

Examine views.

```psql
\dv
```

```text
                 List of relations
 Schema |          Name          | Type |  Owner
--------+------------------------+------+----------
 public | active_collection_view | view | postgres
 public | public_collection_view | view | postgres
(2 rows)
```

```psql
\d+ active_collection_view
```
```text
                             View "public.active_collection_view"
   Column   |          Type          | Collation | Nullable | Default | Storage  | Description
------------+------------------------+-----------+----------+---------+----------+-------------
 identifier | character varying(8)   |           |          |         | extended |
 title      | text                   |           |          |         | extended |
 author     | character varying(255) |           |          |         | extended |
 status     | smallint               |           |          |         | plain    |
View definition:
 SELECT collection.identifier,
    collection.title,
    collection.author,
    collection.status
   FROM collection
  WHERE collection.status = 1;
```

```psql
\d+ public_collection_view
```
```text
                             View "public.public_collection_view"
   Column   |          Type          | Collation | Nullable | Default | Storage  | Description
------------+------------------------+-----------+----------+---------+----------+-------------
 identifier | character varying(8)   |           |          |         | extended |
 title      | text                   |           |          |         | extended |
 author     | character varying(255) |           |          |         | extended |
 year       | character varying(4)   |           |          |         | extended |
View definition:
 SELECT collection.identifier,
    collection.title,
    collection.author,
    collection.year
   FROM collection;

```

Instead of writing long column lists `SELECT identifier, title, author, status` or repeatedly writing `WHERE status = 1`, applications can query the views directly.

```sql
SELECT * FROM public_collection_view;
```
```text
 identifier |    title    |       author        | year
------------+-------------+---------------------+------
 BK000001   | Dune        | Frank Herbert       | 1965
 BK000002   | Don Quixote | Miguel de Cervantes | 1605
(2 rows)
```

```sql
SELECT * FROM active_collection_view;
```
```text
 identifier |    title    |       author        | status
------------+-------------+---------------------+--------
 BK000001   | Dune        | Frank Herbert       |      1
 BK000002   | Don Quixote | Miguel de Cervantes |      1
(2 rows)
```

---

# TRANSACTION — Controlled State Changes

Transactions group multiple SQL operations into a single atomic unit of work.

This provides:

* consistency
* rollback safety
* protection against partial updates

A transaction either succeeds completely or fails completely.

View the current state of the collection table.

```sql
SELECT id,identifier,title,author,status,modified FROM collection;
```
```text
 id | identifier |    title    |       author        | status |          modified
----+------------+-------------+---------------------+--------+----------------------------
  2 | BK000002   | Don Quixote | Miguel de Cervantes |      1 | 2026-05-23 20:51:59.511673
  1 | BK000001   | Dune        | Frank Herbert       |      1 | 2026-05-23 20:51:59.511673
(2 rows)
```

---

## Step 12 — Begin transaction

```sql
BEGIN;
```

---

## Step 13 — Update a record

```sql
UPDATE collection
SET status = 0
WHERE identifier = 'BK000001';
```

This modifies the state of an existing row.

---

## Step 14 — Verify the temporary change

```sql
SELECT id, identifier, title, author, status
FROM collection
WHERE identifier = 'BK000001';
```
```text
 id | identifier | title |    author     | status
----+------------+-------+---------------+--------
  1 | BK000001   | Dune  | Frank Herbert |      0
(1 row)
```

At this point, the update is visible inside the current transaction session but has not yet been permanently committed.

---

## Step 15 — Roll back the transaction

```sql
ROLLBACK;
```

This discards the pending update and restores the previous database state.

```sql
SELECT id, identifier, title, author, status
FROM collection
WHERE identifier = 'BK000001';
```
```text
 id | identifier | title |    author     | status
----+------------+-------+---------------+--------
  1 | BK000001   | Dune  | Frank Herbert |      1
(1 row)
```

---

## Step 16 — Commit example

```sql
BEGIN;

UPDATE collection
SET status = 0
WHERE identifier = 'BK000001';

COMMIT;
```

In this example, the change becomes permanent.

```sql
SELECT id, identifier, title, author, status
FROM collection
WHERE identifier = 'BK000001';
```
```text
 id | identifier | title |    author     | status
----+------------+-------+---------------+--------
  1 | BK000001   | Dune  | Frank Herbert |      0
(1 row)
```

> Note if we try `ROLLBACK` after running `COMMIT` we will receive a warning the transaction has already been completed. This confirms our `UPDATE` transaction is now permanent.

```sql
ROLLBACK;
```
```text
WARNING:  there is no transaction in progress
```

---

# BEHAVIOR — Automated Database Logic

So far, all database operations have been explicitly initiated through SQL statements.

PostgreSQL also supports automated procedural behavior through:

* functions
* procedures
* triggers

These mechanisms allow the database itself to respond automatically to events such as inserts, updates, or deletes.

---

## Step 17 — Create automatic timestamp function

```sql
CREATE OR REPLACE FUNCTION update_modified_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.modified = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

This function updates the `modified` timestamp whenever a row changes.

View functions.

```psql
\df
```
```text
                                List of functions
 Schema |          Name          | Result data type | Argument data types | Type
--------+------------------------+------------------+---------------------+------
 public | update_modified_column | trigger          |                     | func
(1 row)
```
```psql
\sf update_modified_column
```
```text
CREATE OR REPLACE FUNCTION public.update_modified_column()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    NEW.modified = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$function$
```

---

## Step 18 — Attach trigger to the collection table

```sql
CREATE TRIGGER update_collection_modtime
BEFORE UPDATE ON collection
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();
```

This trigger automatically executes the function before every row update.

Unlike some database systems that provide built-in auto-update timestamp column behavior, PostgreSQL exposes this functionality through explicit procedural logic using triggers and functions.

This approach separates:

* structural schema definition
* automated behavioral logic

and makes the behavior fully visible and customizable.

View trigger.

```psql
\dS collection
```
```text
                                            Table "public.collection"
      Column       |            Type             | Collation | Nullable |                Default
-------------------+-----------------------------+-----------+----------+----------------------------------------
 id                | integer                     |           | not null | nextval('collection_id_seq'::regclass)
 identifier        | character varying(8)        |           | not null |
 created           | timestamp without time zone |           | not null | CURRENT_TIMESTAMP
 modified          | timestamp without time zone |           | not null | CURRENT_TIMESTAMP
 status            | smallint                    |           | not null | 1
 author            | character varying(255)      |           | not null |
 year              | character varying(4)        |           | not null |
 title             | text                        |           | not null |
 description       | text                        |           | not null |
 isbn              | character varying(13)       |           | not null |
 language_iso639_3 | character varying(3)        |           | not null |
 root_set          | integer                     |           | not null | 0
 sub_set           | integer                     |           | not null | 0
Indexes:
    "collection_pkey" PRIMARY KEY, btree (id)
    "collection_identifier_key" UNIQUE CONSTRAINT, btree (identifier)
    "idx_collection_description_ft" gin (to_tsvector('english'::regconfig, description))
    "idx_collection_isbn" btree (isbn)
Foreign-key constraints:
    "fk_language" FOREIGN KEY (language_iso639_3) REFERENCES language(iso639_3)
Triggers:
    update_collection_modtime BEFORE UPDATE ON collection FOR EACH ROW EXECUTE FUNCTION update_modified_column()
```

Demonstrate the trigger automatically updating the `modified` column.

View current state of the collection table and note the date and time in the `modified` column.

```sql
SELECT id,identifier,title,author,status,modified FROM collection;
```
```text
 id | identifier |    title    |       author        | status |          modified
----+------------+-------------+---------------------+--------+----------------------------
  2 | BK000002   | Don Quixote | Miguel de Cervantes |      1 | 2026-05-23 20:51:59.511673
  1 | BK000001   | Dune        | Frank Herbert       |      0 | 2026-05-23 20:51:59.511673
(2 rows)
```

Check the current date and time.

```sql
SELECT CURRENT_TIMESTAMP;
```
```text
       current_timestamp
-------------------------------
 2026-05-23 21:08:06.432151+00
(1 row)
```

Run `UPDATE` on a row.

```sql
UPDATE collection SET status = 1 WHERE identifier = 'BK000001';
```

View the `collection` table again and note the `modified` date and time have automatically updated via the trigger operation.

```sql
SELECT id,identifier,title,author,status,modified FROM collection;
```
```text
 id | identifier |    title    |       author        | status |          modified
----+------------+-------------+---------------------+--------+----------------------------
  2 | BK000002   | Don Quixote | Miguel de Cervantes |      1 | 2026-05-23 20:51:59.511673
  1 | BK000001   | Dune        | Frank Herbert       |      1 | 2026-05-23 21:08:09.952737
(2 rows)
```

---

# Part III — Administrative Overview (Light Introduction)

Beyond schema design and data operations, PostgreSQL also includes administrative capabilities for managing real-world deployments.

This section is intentionally minimal, serving only as a conceptual introduction.

---

## Backup and restore

> [https://www.postgresql.org/docs/current/backup.html](https://www.postgresql.org/docs/current/backup.html)


Quit `psql` and return to the bash command line.

```bash
pg_dump -U postgres -C -d half_shell > backup.sql
```

> The dump file is effectively a replayable reconstruction script describing the database structure, data, indexes, procedural objects, and constraints in dependency-safe order.

```bash
cat backup.sql
```

<details>
	<summary>Complete view of PostgreSQL database dump file.</summary>

```sql
--
-- PostgreSQL database dump
--

\restrict RWa5uqFFTlHBluBebvO1bc8esJeGEvYclLSOmjYDbaIuJTy4nKbxM8JP1C9bvaT

-- Dumped from database version 14.22 (Debian 14.22-1.pgdg13+1)
-- Dumped by pg_dump version 14.22 (Debian 14.22-1.pgdg13+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: half_shell; Type: DATABASE; Schema: -; Owner: postgres
--

CREATE DATABASE half_shell WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE = 'en_US.utf8';


ALTER DATABASE half_shell OWNER TO postgres;

\unrestrict RWa5uqFFTlHBluBebvO1bc8esJeGEvYclLSOmjYDbaIuJTy4nKbxM8JP1C9bvaT
\connect half_shell
\restrict RWa5uqFFTlHBluBebvO1bc8esJeGEvYclLSOmjYDbaIuJTy4nKbxM8JP1C9bvaT

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: update_modified_column(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_modified_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.modified = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_modified_column() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: collection; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.collection (
    id integer NOT NULL,
    identifier character varying(8) NOT NULL,
    created timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modified timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    status smallint DEFAULT 1 NOT NULL,
    author character varying(255) NOT NULL,
    year character varying(4) NOT NULL,
    title text NOT NULL,
    description text NOT NULL,
    isbn character varying(13) NOT NULL,
    language_iso639_3 character varying(3) NOT NULL,
    root_set integer DEFAULT 0 NOT NULL,
    sub_set integer DEFAULT 0 NOT NULL
);


ALTER TABLE public.collection OWNER TO postgres;

--
-- Name: active_collection_view; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.active_collection_view AS
 SELECT collection.identifier,
    collection.title,
    collection.author,
    collection.status
   FROM public.collection
  WHERE (collection.status = 1);


ALTER TABLE public.active_collection_view OWNER TO postgres;

--
-- Name: collection_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.collection_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.collection_id_seq OWNER TO postgres;

--
-- Name: collection_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.collection_id_seq OWNED BY public.collection.id;


--
-- Name: language; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.language (
    iso639_3 character varying(3) NOT NULL,
    language_name character varying(64) NOT NULL
);


ALTER TABLE public.language OWNER TO postgres;

--
-- Name: public_collection_view; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.public_collection_view AS
 SELECT collection.identifier,
    collection.title,
    collection.author,
    collection.year
   FROM public.collection;


ALTER TABLE public.public_collection_view OWNER TO postgres;

--
-- Name: collection id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.collection ALTER COLUMN id SET DEFAULT nextval('public.collection_id_seq'::regclass);


--
-- Data for Name: collection; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.collection (id, identifier, created, modified, status, author, year, title, description, isbn, language_iso639_3, root_set, sub_set) FROM stdin;
1       BK000001        2026-05-23 23:07:55.386806      2026-05-23 23:07:55.386806      1       Frank Herbert   1965   Dune                     Science fiction novel set on Arrakis.    9780441172719   eng     0       0
2       BK000002        2026-05-23 23:07:55.386806      2026-05-23 23:07:55.386806      1       Miguel de Cervantes    1605                     Don Quixote      Spanish novel about a wandering knight. 9780060934347   spa     0       0
\.


--
-- Data for Name: language; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.language (iso639_3, language_name) FROM stdin;
eng     English
spa     Spanish
jpn     Japanese
\.


--
-- Name: collection_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.collection_id_seq', 2, true);


--
-- Name: collection collection_identifier_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.collection
    ADD CONSTRAINT collection_identifier_key UNIQUE (identifier);


--
-- Name: collection collection_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.collection
    ADD CONSTRAINT collection_pkey PRIMARY KEY (id);


--
-- Name: language language_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.language
    ADD CONSTRAINT language_pkey PRIMARY KEY (iso639_3);


--
-- Name: idx_collection_description_ft; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_collection_description_ft ON public.collection USING gin (to_tsvector('english'::regconfig, description));


--
-- Name: idx_collection_isbn; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_collection_isbn ON public.collection USING btree (isbn);


--
-- Name: collection update_collection_modtime; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_collection_modtime BEFORE UPDATE ON public.collection FOR EACH ROW EXECUTE FUNCTION public.update_modified_column();


--
-- Name: collection fk_language; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.collection
    ADD CONSTRAINT fk_language FOREIGN KEY (language_iso639_3) REFERENCES public.language(iso639_3);


--
-- PostgreSQL database dump complete
--

\unrestrict RWa5uqFFTlHBluBebvO1bc8esJeGEvYclLSOmjYDbaIuJTy4nKbxM8JP1C9bvaT

```
</details>

Run `psql` again and drop the `half_shell` database.

```sql
DROP DATABASE half_shell;
```

```psql
\list
```
```text
                                 List of databases
   Name    |  Owner   | Encoding |  Collate   |   Ctype    |   Access privileges
-----------+----------+----------+------------+------------+-----------------------
 postgres  | postgres | UTF8     | en_US.utf8 | en_US.utf8 |
 template0 | postgres | UTF8     | en_US.utf8 | en_US.utf8 | =c/postgres          +
           |          |          |            |            | postgres=CTc/postgres
 template1 | postgres | UTF8     | en_US.utf8 | en_US.utf8 | =c/postgres          +
           |          |          |            |            | postgres=CTc/postgres
(3 rows)
```

```psql
\c half_shell
```
```text
connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: FATAL:  database "half_shell" does not exist
Previous connection kept
```

Return to bash shell and restore the `half_shell` database from the dump file.

```bash
psql -U postgres < backup.sql
```

<details>
	<summary>Complete output of psql database restore.</summary>
	
```text
SET
SET
SET
SET
SET
 set_config
------------

(1 row)

SET
SET
SET
SET
CREATE DATABASE
ALTER DATABASE
You are now connected to database "half_shell" as user "postgres".
SET
SET
SET
SET
SET
 set_config
------------

(1 row)

SET
SET
SET
SET
CREATE FUNCTION
ALTER FUNCTION
SET
SET
CREATE TABLE
ALTER TABLE
CREATE VIEW
ALTER TABLE
CREATE SEQUENCE
ALTER TABLE
ALTER SEQUENCE
CREATE TABLE
ALTER TABLE
CREATE VIEW
ALTER TABLE
ALTER TABLE
COPY 2
COPY 3
 setval
--------
      2
(1 row)

ALTER TABLE
ALTER TABLE
ALTER TABLE
CREATE INDEX
CREATE INDEX
CREATE TRIGGER
ALTER TABLE
```
</details>

Confirm the restoration.

```bash
psql -U postgres
```

```psql
\list
```
```text
                                 List of databases
    Name    |  Owner   | Encoding |  Collate   |   Ctype    |   Access privileges
------------+----------+----------+------------+------------+-----------------------
 half_shell | postgres | UTF8     | en_US.utf8 | en_US.utf8 |
 postgres   | postgres | UTF8     | en_US.utf8 | en_US.utf8 |
 template0  | postgres | UTF8     | en_US.utf8 | en_US.utf8 | =c/postgres          +
            |          |          |            |            | postgres=CTc/postgres
 template1  | postgres | UTF8     | en_US.utf8 | en_US.utf8 | =c/postgres          +
            |          |          |            |            | postgres=CTc/postgres
(4 rows)
```

```psql
\c half_shell
```

```sql
SELECT
	c.title,
	c.author,
	l.language_name
FROM collection c
JOIN language l
ON c.language_iso639_3 = l.iso639_3
```
```text
    title    |       author        | language_name
-------------+---------------------+---------------
 Dune        | Frank Herbert       | English
 Don Quixote | Miguel de Cervantes | Spanish
(2 rows)
```

---

## Monitoring database activity

> [https://www.postgresql.org/docs/current/monitoring.html](https://www.postgresql.org/docs/current/monitoring.html)

```sql
SELECT datname,
       usename,
       application_name,
       client_addr,
       backend_start,
       state
FROM pg_stat_activity;
```
```text
 datname  | usename  | application_name | client_addr |         backend_start         | state
----------+----------+------------------+-------------+-------------------------------+--------
          |          |                  |             | 2026-05-23 23:04:30.116674+00 |
          | postgres |                  |             | 2026-05-23 23:04:30.129731+00 |
 postgres | postgres | psql             |             | 2026-05-23 23:52:00.412109+00 | active
          |          |                  |             | 2026-05-23 23:04:30.113005+00 |
          |          |                  |             | 2026-05-23 23:04:30.111347+00 |
          |          |                  |             | 2026-05-23 23:04:30.117261+00 |
(6 rows)
```

This view provides a real-time snapshot of database connections and activity.

---

# Conclusion

Lab 1 introduced PostgreSQL as a visible operating system process and storage system. Instead of treating SQL as an isolated query language, we examined how the database server exists as a real running environment composed of processes, files, memory usage, and persistent storage structures. From that foundation, we performed the simplest possible SQL operations while observing how the system responded at each layer.

Lab 2 extended that foundation from observation into intentional design. Rather than interacting with isolated commands, we constructed a small relational schema and explored how structure, querying, transactions, views, and procedural behavior combine into a coherent database system.

Several important relational concepts were introduced:

* schema definition through DDL
* CRUD-style data interaction through DML
* foreign key relationships between tables
* reusable query abstraction through views
* transactional safety through `BEGIN`, `COMMIT`, and `ROLLBACK`
* automated database-side behavior using functions and triggers

The progression of the implementation was intentionally layered:

1. define structure
2. insert and retrieve data
3. abstract queries into reusable interfaces
4. protect state changes with transactions
5. automate behavior inside the database engine itself

This mirrors how relational systems evolve in practical environments. Databases are not only collections of tables and queries, but systems for managing structure, consistency, behavior, and controlled state over time.

The `half_shell` schema remains intentionally small, but the concepts demonstrated scale directly into larger production systems. The same principles used here—constraints, relationships, views, transactions, indexing, and procedural automation—form the foundation of real-world PostgreSQL applications.

Future labs can build naturally from this point into more advanced querying and database behavior, including:

* aggregation and grouping
* advanced JOIN patterns
* window functions
* Common Table Expressions (CTEs)
* execution planning with `EXPLAIN`
* indexing strategy and optimization
* full-text querying
* concurrency and isolation behavior

At this stage, the goal is not mastery of SQL syntax, but the development of a structured mental model of how relational databases are designed, queried, maintained, and controlled.
