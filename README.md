# Postgres Secure Automated Backup Solution

This repository provides a solution for automating PostgreSQL database backups and their verification. The solution allows you to:

- Automatically back up PostgreSQL databases.
- Compress & Encrypt backups.
- Verify backup integrity by restoring them into a test database.
- Store backups in an object storage system (e.g., MinIO or AWS S3).
- Make backups immutable using the MinIO client (`mc`).

## Prerequisites

Before using this system, ensure the following:

### 1. Docker

### 2. Create a Backup User in PostgreSQL

You need to create a PostgreSQL user that has read-only permissions for the databases you want to back up. This user will be used by the backup scripts to perform backups. You can create this user by running the following commands:

first connect(\c command) to your database using psql, then run:

```sql
CREATE USER backup_user WITH PASSWORD 'strongpassword';

-- Grant connection and schema access
GRANT CONNECT ON DATABASE <database_name> TO backup_user;
GRANT USAGE ON SCHEMA public TO backup_user;

-- Grant read-only on all existing tables
GRANT SELECT ON ALL TABLES IN SCHEMA public TO backup_user;

-- Grant read-only on all sequences
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO backup_user;

-- Make sure future tables and sequences get permission too
ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT SELECT ON TABLES TO backup_user;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT USAGE, SELECT ON SEQUENCES TO backup_user;
```

### 3. Make an Immutable S3 bucket (WORM)

```bash
mc alias set storage <S3_URL> <ACCESS_KEY> <SECRET_KEY> --api s3V4
mc mb --with-lock storage/backup
mc retention set --default compliance 30d storage/backup
```

### 4. Create a write-only access S3 user
We will use this user's credentials to upload backups to S3.


## Run

### 1. Setup Environment variables
Make a copy of `.env.example` as `.env` and put your environment variables

### 2. Run
```bash
docker compose up
```
