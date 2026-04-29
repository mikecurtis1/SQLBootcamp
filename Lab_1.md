# SQL Lab 1

This lab begins from a completely empty starting point and builds a working PostgreSQL environment step by step. We first establish and observe the system itself—verifying the container, processes, and file structure—before interacting with the database server. From there, we perform the simplest possible operations: creating a database and table, inserting a small piece of data, and then removing those objects. The goal is not complexity, but clarity—demonstrating how each action is explicitly executed and how the system responds at each stage.

This approach differs from the more common pattern of starting with an existing database and immediately running queries like `SELECT * FROM table;`. While that can be convenient, it often hides the underlying structure and assumptions about how the database was created and how data got there. By building everything from zero, each step is visible and intentional, making it easier to understand how the system works and to reason about it later when the environment is more complex.

This lab intentionally moves between three layers—the operating system, the database engine, and SQL—to show how they relate to each other.

* **System layer** (Linux, processes, disk, `$PGDATA`)
* **Database engine layer** (Postgres processes, catalogs, storage layout)
* **SQL interface layer** (DDL/DML, CRUD)

---

## Docker setup

This section sets up a local PostgreSQL server using Docker so we can connect to it with `psql`.

### Dockerfile contents

This uses the official PostgreSQL image as a base. No additional configuration is added.

> <https://hub.docker.com/_/postgres>

Create a work directory for the lab.

```bash
mkdir ~/sql_lab_1
```

Change to the lab directory.

```bash
cd ~/sql_lab_1
```

Create a Dockerfile

```bash
touch Dockerfile
```

> <https://docs.docker.com/reference/dockerfile/>

Docker can build images automatically by reading the instructions from a Dockerfile.

Add one config line specifying the Postgres image to the Dockerfile.

```text
FROM postgres:14.22
```

### Build image

From the lab work directory execute...

```bash
docker build -t postgres-dev .
```

> <https://docs.docker.com/reference/cli/docker/image/build/>

* `docker image build [OPTIONS] PATH | URL | -`
* `docker build` is an alias for `docker image build`
* `-t` tag for image
* `.` is the path
* By default Docker looks for a file named `Dockerfile`, but there is an option of specify another file name with the `-f` flag

### Run image in a container

From the lab work directory execute...

```bash
docker run --name postgres-dev-cont -e POSTGRES_PASSWORD=root -d postgres-dev -c log_statement=all
```

> <https://docs.docker.com/reference/cli/docker/container/run/>

* `docker container run [OPTIONS] IMAGE [COMMAND] [ARG...]`
* `docker run` is an alias for `docker container run`
* `--name` name for container
* `-e` Set environment variables
* `-d` detach
* `postgres-dev` is the image name defined by the `-t` flag in the `build` step.
* `-c` passes the configuration setting directly to the PostgreSQL server daemon. We will use it to set the Postgres logging level to `all`. We will see the effect of this option at the end of the lab where we review logging which includes all SQL statements.

> <https://hub.docker.com/_/postgres>

The Docker `run` command can take environment variable arguments which are specific to the Docker image so we should refer back to the Docker image notes for available environment options.

* The default `postgres` user and database are created in the entrypoint with `initdb`. We will see a reference to this at the end of the lab, in the logging section, where log line `/usr/local/bin/docker-entrypoint.sh: ignoring /docker-entrypoint-initdb.d/*` appears.
* `POSTGRES_USER` If it is not specified, then the default user of `postgres` will be used.
* The PostgreSQL image uses several environment variables which are easy to miss. The only variable required is `POSTGRES_PASSWORD`, the rest are optional.
* We are not exposing a port for Postgres because we will connect from inside the container.

---

## Check the Docker environment

### List Docker images and note image ID and tag.

Command 

```bash
docker images
```

Output

```
IMAGE                 ID             DISK USAGE   CONTENT SIZE   EXTRA
postgres-dev:latest   f50729e01ba7        622MB          157MB    U
```

### List Docker containers and note container name.

Command

```bash
docker ps
```

Output

```
CONTAINER ID   IMAGE          COMMAND                  CREATED        STATUS        PORTS      NAMES
ff9f14dcab8d   postgres-dev   "docker-entrypoint.s…"   39 hours ago   Up 39 hours   5432/tcp   postgres-dev-cont
```

---

## Open an interactive shell inside the running container.

### Connect directly to `psql`

```bash
docker exec -it postgres-dev-cont psql -U postgres
```

### Connect to bash shell

Alternatively, we can connect to a bash shell to explore the Linux environment inside the container, and then we can start the `psql` client later.

```bash
docker exec -it postgres-dev-cont bash
```

---

## Examine the Linux environment of the container

> This section explores the underlying Linux environment of the container to show that PostgreSQL is not just a query interface, but a running system built on processes, memory, and a file system. By examining system commands, active processes, and the `$PGDATA` directory, we can see how the database operates beneath the SQL layer. While this level of detail is not required for basic usage, it becomes important in administrative work—such as diagnosing slow queries, monitoring resource usage, understanding connections, and managing storage—where database behavior must be interpreted in terms of CPU, memory, disk I/O, and system processes.

> A few utilities need to be installed with `apt`. These utilities are not necessary to run Postgres, but provided tools for more detailed examination of the Linux system and resources.

### General system and resources

Command
```bash
whoami
```
Output
```
root
```

Command
```bash
pwd
```
Output
```text
/
```

Command
```bash
ls -lah
```
Output
```
total 64K
drwxr-xr-x   1 root root 4.0K Apr 26 23:30 .
drwxr-xr-x   1 root root 4.0K Apr 26 23:30 ..
lrwxrwxrwx   1 root root    7 Mar  2 21:50 bin -> usr/bin
drwxr-xr-x   2 root root 4.0K Mar  2 21:50 boot
drwxr-xr-x   5 root root  340 Apr 26 23:30 dev
drwxr-xr-x   2 root root 4.0K Apr 22 01:32 docker-entrypoint-initdb.d
-rwxr-xr-x   1 root root    0 Apr 26 23:30 .dockerenv
drwxr-xr-x   1 root root 4.0K Apr 26 23:30 etc
drwxr-xr-x   2 root root 4.0K Mar  2 21:50 home
lrwxrwxrwx   1 root root    7 Mar  2 21:50 lib -> usr/lib
lrwxrwxrwx   1 root root    9 Mar  2 21:50 lib64 -> usr/lib64
drwxr-xr-x   2 root root 4.0K Apr 21 00:00 media
drwxr-xr-x   2 root root 4.0K Apr 21 00:00 mnt
drwxr-xr-x   2 root root 4.0K Apr 21 00:00 opt
dr-xr-xr-x 259 root root    0 Apr 26 23:30 proc
drwx------   1 root root 4.0K Apr 28 14:15 root
drwxr-xr-x   1 root root 4.0K Apr 22 01:33 run
lrwxrwxrwx   1 root root    8 Mar  2 21:50 sbin -> usr/sbin
drwxr-xr-x   2 root root 4.0K Apr 21 00:00 srv
dr-xr-xr-x  13 root root    0 Apr 15 15:27 sys
drwxrwxrwt   2 root root 4.0K Apr 21 00:00 tmp
drwxr-xr-x   1 root root 4.0K Apr 21 00:00 usr
drwxr-xr-x   1 root root 4.0K Apr 21 00:00 var
```

Command
```bash
uname -r
```
Output
```
6.6.87.2-microsoft-standard-WSL2
```

Command
```bash
uname -a
```
Output
```
Linux ff9f14dcab8d 6.6.87.2-microsoft-standard-WSL2 #1 SMP PREEMPT_DYNAMIC Thu Jun  5 18:30:46 UTC 2025 x86_64 GNU/Linux
```

Command
```bash
bash --version
```
Output
```
GNU bash, version 5.2.37(1)-release (x86_64-pc-linux-gnu)
Copyright (C) 2022 Free Software Foundation, Inc.
License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>

This is free software; you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.
```

Command
```bash
cat /etc/os-release
```
Output
```
PRETTY_NAME="Debian GNU/Linux 13 (trixie)"
NAME="Debian GNU/Linux"
VERSION_ID="13"
VERSION="13 (trixie)"
VERSION_CODENAME=trixie
DEBIAN_VERSION_FULL=13.4
ID=debian
HOME_URL="https://www.debian.org/"
SUPPORT_URL="https://www.debian.org/support"
BUG_REPORT_URL="https://bugs.debian.org/"
```

Command
```bash
uptime
```
Output
```
14:26:26 up 1 day, 13:29,  0 users,  load average: 0.14, 0.13, 0.14
```

Command
```bash
date
```
Output
```
Tue Apr 28 02:26:30 PM UTC 2026
```

Command
```bash
free -m
```
Output
```
               total        used        free      shared  buff/cache   available
Mem:            3849        1004         955          19        2089        2845
Swap:           1024           0        1024
```

Command
```bash
df -h
```
Output
```
Filesystem      Size  Used Avail Use% Mounted on
overlay        1007G  3.2G  953G   1% /
tmpfs            64M     0   64M   0% /dev
shm              64M   28K   64M   1% /dev/shm
/dev/sdf       1007G  3.2G  953G   1% /etc/hosts
tmpfs           1.9G     0  1.9G   0% /proc/acpi
tmpfs           1.9G     0  1.9G   0% /proc/scsi
tmpfs           1.9G     0  1.9G   0% /sys/firmware
```

Command 
```bash
du / --exclude='/proc' -sh
```
Output
```
510M    /
```

Command
```bash
apt update && apt install sysstat
```

```bash
iostat
```
Output
```
Linux 6.6.87.2-microsoft-standard-WSL2 (ff9f14dcab8d)   04/28/2026      _x86_64_        (4 CPU)

avg-cpu:  %user   %nice %system %iowait  %steal   %idle
           0.77    0.02    1.16    0.44    0.00   97.60

Device             tps    kB_read/s    kB_wrtn/s    kB_dscd/s    kB_read    kB_wrtn    kB_dscd
loop0             0.12        11.49         0.00         0.00    1599746          0          0
loop1             0.34        24.66         0.00         0.00    3432189          0          0
sda               0.04         1.79         0.00         0.00     249125          0          0
sdb               0.00         0.13         0.00         0.00      18449          0          0
sdc               0.00         0.02         0.00         0.00       2228          4          0
sdd               7.50        58.25       106.42       446.31    8107085   14810780   62114504
sde               0.01         0.42         0.00         0.00      57970        204          7
sdf               1.22        23.53        15.02      7616.17    3274937    2090468 1059961264
```

### Postgres specific system details

> So far, our Linux exploration has provided a general view into the file system and resources. The following commands will provide system information specifically related to Postgres. 

Command
```bash
ps -ef
```
Output
```
UID        PID  PPID  C STIME TTY          TIME CMD
postgres     1     0  0 13:21 ?        00:00:01 postgres
postgres    63     1  0 13:21 ?        00:00:00 postgres: checkpointer
postgres    64     1  0 13:21 ?        00:00:00 postgres: background writer
postgres    65     1  0 13:21 ?        00:00:00 postgres: walwriter
postgres    66     1  0 13:21 ?        00:00:00 postgres: autovacuum launcher
postgres    67     1  0 13:21 ?        00:00:00 postgres: stats collector
postgres    68     1  0 13:21 ?        00:00:00 postgres: logical replication launcher
root       417     0  0 16:11 pts/0    00:00:00 bash
root       591   417  0 16:32 pts/0    00:00:00 ps -ef
```

> Note that only a small number of processes are running. In a container, the primary process (here `postgres`, PID 1) and its child processes make up the entire system. Docker streamlines the system to only what is needed.

Command
```bash
 top
```
Output
```
top - 14:26:44 up 1 day, 13:29,  0 users,  load average: 0.11, 0.12, 0.13
Tasks:   9 total,   1 running,   8 sleeping,   0 stopped,   0 zombie
%Cpu(s):  1.9 us,  5.8 sy,  0.0 ni, 92.3 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st
MiB Mem :   3849.2 total,    955.1 free,   1004.4 used,   2089.9 buff/cache
MiB Swap:   1024.0 total,   1024.0 free,      0.0 used.   2844.8 avail Mem

  PID USER      PR  NI    VIRT    RES    SHR S  %CPU  %MEM     TIME+ COMMAND
  403 root      20   0   10356   5248   3200 R  16.7   0.1   0:00.04 top
    1 postgres  20   0  215168  28032  25984 S   0.0   0.7   0:01.67 postgres
   63 postgres  20   0  215284  11128   9088 S   0.0   0.3   0:00.29 postgres
   64 postgres  20   0  215168   7672   5632 S   0.0   0.2   0:00.24 postgres
   65 postgres  20   0  215168   9848   7808 S   0.0   0.2   0:00.44 postgres
   66 postgres  20   0  215708   8312   6016 S   0.0   0.2   0:00.58 postgres
   67 postgres  20   0   69892   5368   3328 S   0.0   0.1   0:00.71 postgres
   68 postgres  20   0  215600   7416   5248 S   0.0   0.2   0:00.07 postgres
  364 root      20   0    7340   3968   3456 S   0.0   0.1   0:00.35 bash
```

Command
```bash
env
```
Output
```
HOSTNAME=ff9f14dcab8d
POSTGRES_PASSWORD=root
PWD=/
HOME=/root
LANG=en_US.utf8
GOSU_VERSION=1.19
PG_MAJOR=14
PG_VERSION=14.22-1.pgdg13+1
TERM=xterm
SHLVL=1
PGDATA=/var/lib/postgresql/data
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/lib/postgresql/14/bin
_=/usr/bin/env
```

Command
```bash
echo $PGDATA
```
Output
```
/var/lib/postgresql/data
```

> `PGDATA` is the directory where PostgreSQL stores all database files.
> 
> At a high level:
> *base/ stores actual table data (per database)
> *global/ stores cluster-wide system tables
> *pg_wal/ stores write-ahead logs for durability”
>
> The Write-Ahead Log (WAL) is the primary mechanism PostgreSQL uses to ensure data integrity and durability (the 'D' in ACID). Its core principle is that all changes to data files must be recorded in a log before those changes are applied to the actual database tables or indexes.

Command
```bash
ls -lah $PGDATA
```
Output
```
total 136K
drwx------ 19 postgres postgres 4.0K Apr 26 23:30 .
drwxrwxrwt  1 postgres postgres 4.0K Apr 22 01:33 ..
drwx------  6 postgres postgres 4.0K Apr 27 12:46 base
drwx------  2 postgres postgres 4.0K Apr 27 12:51 global
drwx------  2 postgres postgres 4.0K Apr 26 23:30 pg_commit_ts
drwx------  2 postgres postgres 4.0K Apr 26 23:30 pg_dynshmem
-rw-------  1 postgres postgres 4.8K Apr 26 23:30 pg_hba.conf
-rw-------  1 postgres postgres 1.6K Apr 26 23:30 pg_ident.conf
drwx------  4 postgres postgres 4.0K Apr 27 13:12 pg_logical
drwx------  4 postgres postgres 4.0K Apr 26 23:30 pg_multixact
drwx------  2 postgres postgres 4.0K Apr 26 23:30 pg_notify
drwx------  2 postgres postgres 4.0K Apr 26 23:30 pg_replslot
drwx------  2 postgres postgres 4.0K Apr 26 23:30 pg_serial
drwx------  2 postgres postgres 4.0K Apr 26 23:30 pg_snapshots
drwx------  2 postgres postgres 4.0K Apr 26 23:30 pg_stat
drwx------  2 postgres postgres 4.0K Apr 28 15:28 pg_stat_tmp
drwx------  2 postgres postgres 4.0K Apr 26 23:30 pg_subtrans
drwx------  2 postgres postgres 4.0K Apr 26 23:30 pg_tblspc
drwx------  2 postgres postgres 4.0K Apr 26 23:30 pg_twophase
-rw-------  1 postgres postgres    3 Apr 26 23:30 PG_VERSION
drwx------  3 postgres postgres 4.0K Apr 26 23:30 pg_wal
drwx------  2 postgres postgres 4.0K Apr 26 23:30 pg_xact
-rw-------  1 postgres postgres   88 Apr 26 23:30 postgresql.auto.conf
-rw-------  1 postgres postgres  29K Apr 26 23:30 postgresql.conf
-rw-------  1 postgres postgres   36 Apr 26 23:30 postmaster.opts
-rw-------  1 postgres postgres   94 Apr 26 23:30 postmaster.pid
```

> These files are managed internally by PostgreSQL and should not be modified directly.

Command

* <https://www.postgresql.org/docs/current/storage-file-layout.html>
* For each database in the cluster there is a subdirectory within PGDATA/base, named after the database's OID in pg_database. This subdirectory is the default location for the database's files; in particular, its system catalogs are stored there.

```bash
ls -lah $PGDATA/base
```
Output
```
total 24K
drwx------  6 postgres postgres 4.0K Apr 27 12:46 .
drwx------ 19 postgres postgres 4.0K Apr 26 23:30 ..
drwx------  2 postgres postgres 4.0K Apr 26 23:30 1
drwx------  2 postgres postgres 4.0K Apr 26 23:30 13843
drwx------  2 postgres postgres 4.0K Apr 27 12:52 13844
drwx------  2 postgres postgres 4.0K Apr 27 12:53 16390
```

Command
```bash
ls -lah $PGDATA/global
```
Output
```
total 572K
drwx------  2 postgres postgres 4.0K Apr 27 12:51 .
drwx------ 19 postgres postgres 4.0K Apr 26 23:30 ..
-rw-------  1 postgres postgres 8.0K Apr 26 23:30 1213
-rw-------  1 postgres postgres  24K Apr 26 23:30 1213_fsm
-rw-------  1 postgres postgres 8.0K Apr 26 23:30 1213_vm
-rw-------  1 postgres postgres 8.0K Apr 26 23:30 1214
-rw-------  1 postgres postgres  24K Apr 26 23:30 1214_fsm
-rw-------  1 postgres postgres 8.0K Apr 26 23:30 1214_vm
-rw-------  1 postgres postgres  16K Apr 26 23:30 1232
-rw-------  1 postgres postgres  16K Apr 26 23:30 1233
-rw-------  1 postgres postgres 8.0K Apr 26 23:30 1260
-rw-------  1 postgres postgres  24K Apr 26 23:30 1260_fsm
-rw-------  1 postgres postgres 8.0K Apr 26 23:30 1260_vm
-rw-------  1 postgres postgres 8.0K Apr 26 23:30 1261
-rw-------  1 postgres postgres  24K Apr 26 23:30 1261_fsm
-rw-------  1 postgres postgres 8.0K Apr 26 23:30 1261_vm
-rw-------  1 postgres postgres 8.0K Apr 27 12:51 1262
-rw-------  1 postgres postgres  24K Apr 26 23:30 1262_fsm
-rw-------  1 postgres postgres 8.0K Apr 26 23:30 1262_vm
-rw-------  1 postgres postgres 8.0K Apr 26 23:30 2396
-rw-------  1 postgres postgres  24K Apr 26 23:30 2396_fsm
-rw-------  1 postgres postgres 8.0K Apr 26 23:30 2396_vm
-rw-------  1 postgres postgres  16K Apr 26 23:30 2397
-rw-------  1 postgres postgres  16K Apr 27 12:46 2671
-rw-------  1 postgres postgres  16K Apr 27 12:46 2672
-rw-------  1 postgres postgres  16K Apr 26 23:30 2676
-rw-------  1 postgres postgres  16K Apr 26 23:30 2677
-rw-------  1 postgres postgres  16K Apr 26 23:30 2694
-rw-------  1 postgres postgres  16K Apr 26 23:30 2695
-rw-------  1 postgres postgres  16K Apr 26 23:30 2697
-rw-------  1 postgres postgres  16K Apr 26 23:30 2698
-rw-------  1 postgres postgres    0 Apr 26 23:30 2846
-rw-------  1 postgres postgres 8.0K Apr 26 23:30 2847
-rw-------  1 postgres postgres    0 Apr 26 23:30 2964
-rw-------  1 postgres postgres 8.0K Apr 26 23:30 2965
-rw-------  1 postgres postgres    0 Apr 26 23:30 2966
-rw-------  1 postgres postgres 8.0K Apr 26 23:30 2967
-rw-------  1 postgres postgres    0 Apr 26 23:30 3592
-rw-------  1 postgres postgres 8.0K Apr 26 23:30 3593
-rw-------  1 postgres postgres    0 Apr 26 23:30 4060
-rw-------  1 postgres postgres 8.0K Apr 26 23:30 4061
-rw-------  1 postgres postgres    0 Apr 26 23:30 4175
-rw-------  1 postgres postgres 8.0K Apr 26 23:30 4176
-rw-------  1 postgres postgres    0 Apr 26 23:30 4177
-rw-------  1 postgres postgres 8.0K Apr 26 23:30 4178
-rw-------  1 postgres postgres    0 Apr 26 23:30 4181
-rw-------  1 postgres postgres 8.0K Apr 26 23:30 4182
-rw-------  1 postgres postgres    0 Apr 26 23:30 4183
-rw-------  1 postgres postgres 8.0K Apr 26 23:30 4184
-rw-------  1 postgres postgres    0 Apr 26 23:30 4185
-rw-------  1 postgres postgres 8.0K Apr 26 23:30 4186
-rw-------  1 postgres postgres    0 Apr 26 23:30 6000
-rw-------  1 postgres postgres 8.0K Apr 26 23:30 6001
-rw-------  1 postgres postgres 8.0K Apr 26 23:30 6002
-rw-------  1 postgres postgres    0 Apr 26 23:30 6100
-rw-------  1 postgres postgres 8.0K Apr 26 23:30 6114
-rw-------  1 postgres postgres 8.0K Apr 26 23:30 6115
-rw-------  1 postgres postgres 8.0K Apr 27 13:12 pg_control
-rw-------  1 postgres postgres  512 Apr 26 23:30 pg_filenode.map
-rw-------  1 postgres postgres  24K Apr 27 12:51 pg_internal.init
```

Command
```bash
du $PGDATA --exclude='/proc' -sh
```
Output
```
42M     /var/lib/postgresql/data
```

> After the initial installation of Postgres `$PGDATA` is using `42M` of space.

---

Command
```bash
cat $PGDATA/postmaster.pid
```
Output
```
1
/var/lib/postgresql/data
1777246204
5432
/var/run/postgresql
*
    20309         5
ready
```

Command
```bash
ps 1
```
Output
```
  PID TTY      STAT   TIME COMMAND
    1 ?        Ss     0:01 postgres
```

Command
```bash
ps -C postgres
```
Output
```
  PID TTY          TIME CMD
    1 ?        00:00:01 postgres
   63 ?        00:00:00 postgres
   64 ?        00:00:00 postgres
   65 ?        00:00:00 postgres
   66 ?        00:00:00 postgres
   67 ?        00:00:00 postgres
   68 ?        00:00:00 postgres
```

Command
```bash
apt update && apt install psmisc
```

Command
```bash
pstree -psc 1
```
Output
```
postgres(1)─┬─postgres(63)
            ├─postgres(64)
            ├─postgres(65)
            ├─postgres(66)
            ├─postgres(67)
            └─postgres(68)
```

> PostgreSQL uses multiple background processes (checkpointer, writer, autovacuum, etc.) to manage database operations.

---

## Begin SQL work

### CRUD

CRUD stands for **Create**, **Read**, **Update**, **Delete**, which are the four fundamental operations for working with data. These concepts exist independently of any specific database system and describe how data is added, viewed, modified, and removed.

In SQL, these operations are expressed through **Data Manipulation Language (DML)** commands:

* **Create** → `INSERT` (add new rows of data)
* **Read** → `SELECT` (retrieve data)
* **Update** → `UPDATE` (modify existing data)
* **Delete** → `DELETE` (remove data)

In addition to working with data, SQL also includes **Data Definition Language (DDL)** commands, which define and modify the structure of the database itself (tables, columns, etc.):

> **DDL (structure)** → `CREATE`, `ALTER`, `DROP`  
> **DML (data)** → `INSERT`, `SELECT`, `UPDATE`, `DELETE`

DDL defines what exists, while DML operates on what exists.

In this lab, we will begin by using DDL commands to create a simple table, and then apply CRUD operations through DML commands to insert and retrieve data. This establishes the basic pattern of defining structure first, then working with the data stored within it.

### Connect to bash shell and start psql client

```bash
docker exec -it postgres-dev-cont bash
```

```bash
psql -U postgres
```

### Postgres meta-commands reference

> <https://www.postgresql.org/docs/14/app-psql.html>

```psql
psql -V -- display Postgres version
```

```psql
\list -- list databases
```

```psql
\q -- quit psql
```

```psql
\c <db-name> -- connect to a database
```

```psql
\dt -- list tables
```

```psql
\d <table-name> -- describe table
```

```psql
\conninfo -- show current database connection, including the database name, user, host, and port
```

### Explore PostgreSQL environment

Command
```sql
SELECT version();
```
output
```
                                                       version
----------------------------------------------------------------------------------------------------------------------
 PostgreSQL 14.22 (Debian 14.22-1.pgdg13+1) on x86_64-pc-linux-gnu, compiled by gcc (Debian 14.2.0-19) 14.2.0, 64-bit
(1 row)
```
---

Command
```sql
SELECT current_user;
```
output
```
 current_user
--------------
 postgres
(1 row)
```

> Note, `postgres` is the default user installed for the Docker Postgres image during our initial Docker setup steps.

---

Command
```sql
SELECT current_database();
```
output
```
 current_database
------------------
 postgres
(1 row)
```

> What is the `postgres` database?
>
> * Initial Connection Point: Because a client must connect to some database before it can run any SQL (including CREATE DATABASE), the postgres database provides that initial landing spot after installation.
>
> * Default for Utilities: Many built-in and third-party tools (like psql or pgAdmin) assume this database exists and will attempt to connect to it by default if no other name is provided.


> Also note the command prompt reflects the database we are connect to: `postgres=#`

---

Command
```sql
SELECT datname, usename, application_name, client_addr, backend_start, state FROM pg_stat_activity;
```
output
```
 datname  | usename  | application_name | client_addr |         backend_start         | state
----------+----------+------------------+-------------+-------------------------------+--------
          |          |                  |             | 2026-04-26 23:30:04.670386+00 |
          | postgres |                  |             | 2026-04-26 23:30:04.67253+00  |
 postgres | postgres | psql             |             | 2026-04-28 21:41:20.468102+00 | active
          |          |                  |             | 2026-04-26 23:30:04.668132+00 |
          |          |                  |             | 2026-04-26 23:30:04.666932+00 |
          |          |                  |             | 2026-04-26 23:30:04.669074+00 |
(6 rows)
```

> `pg_stat_activity` is a built-in PostgreSQL system view providing a real-time snapshot of current server processes, essential for diagnosing performance issues.
>
> Each row in pg_stat_activity corresponds to a backend process visible at the OS level. We saw these associated processes above in the output from Linux commands `ps -f`, `ps -C postgres`, and `pstree -psc 1`.

---

Command
```sql
\list
```
output
```
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
---

### Create a simple demo database step-by-step

Command
```sql
CREATE DATABASE mydb;
```
output
```
CREATE DATABASE
```
---

Command
```sql
\list
```
output
```
                                 List of databases
   Name    |  Owner   | Encoding |  Collate   |   Ctype    |   Access privileges
-----------+----------+----------+------------+------------+-----------------------
 mydb      | postgres | UTF8     | en_US.utf8 | en_US.utf8 |
 postgres  | postgres | UTF8     | en_US.utf8 | en_US.utf8 |
 template0 | postgres | UTF8     | en_US.utf8 | en_US.utf8 | =c/postgres          +
           |          |          |            |            | postgres=CTc/postgres
 template1 | postgres | UTF8     | en_US.utf8 | en_US.utf8 | =c/postgres          +
           |          |          |            |            | postgres=CTc/postgres
(4 rows)
```
---

Command
```sql
\c mydb
```
output
```
You are now connected to database "mydb" as user "postgres".
```

> Notice our command prompt has changed to the current database: `mydb=#`

---

Command
```sql
\dt
```
output
```
Did not find any relations.
```

> This means there are not yet any tables in our new database.

---

Command
```sql
CREATE TABLE my_table ();
```
output
```
CREATE TABLE;
```

> In practice, columns are usually defined at creation time, but this lab intentionally separates object creation from schema definition.
>
> A table is an object that exists independently of its columns.
>
> Internally, PostgreSQL treats:
> 
> * the table itself (a relation)
> * the columns (attributes)
> 
> as separable pieces of metadata.
>
> This separation mirrors how PostgreSQL internally stores metadata—tables and columns are related but distinct objects.

---

Command
```psql
\dt
```
output
```
          List of relations
 Schema |   Name   | Type  |  Owner
--------+----------+-------+----------
 public | my_table | table | postgres
(1 row)
```

> `\dt` provides a list of tables.

---

Command
```psql
\d my_table
```
output
```
            Table "public.my_table"
 Column | Type | Collation | Nullable | Default
--------+------+-----------+----------+---------
```

> `\d <table-name>` provides column details for a single table. In this case we have a table but at this point it contains no columns. We will add columns below.
>
> Notice while we asked for `my_table` the name in the output shows a prefix of `public.` to give name `public.my_table`. We will discuss the significance of that below.

---

Command
```sql
ALTER TABLE my_table ADD COLUMN field_1 text;
```
output
```
ALTER TABLE
```

> In the command above, the final argument `text` provides a required _data type_. See, <https://www.postgresql.org/docs/14/datatype.html> for data type details.

---

Command
```psql
\d my_table
```
output
```
             Table "public.my_table"
 Column  | Type | Collation | Nullable | Default
---------+------+-----------+----------+---------
 field_1 | text |           |          |
```
---

Command
```sql
SELECT field_1 FROM my_table;
```
output
```
 field_1
---------
(0 rows)
```
---

Command
```sql
INSERT INTO my_table (field_1) VALUES ('hello');
```
output
```
INSERT 0 1
```
---

Command
```sql
SELECT field_1 FROM my_table;
```
output
```
 field_1
---------
 hello
(1 row)
```
---

Command
```psql
\dn
```
output
```
  List of schemas
  Name  |  Owner
--------+----------
 public | postgres
(1 row)
```

> Lists schemas (namespaces). Namespaces come into play in complex database to manage security vulnerabilities, name collisions, logical organization, access control, and multi-tenant architecture.
>
> The `public` schema is the default namespace created in every new PostgreSQL database. It serves as a shared area where tables and other objects are automatically placed if no specific schema is specified during creation.

---

Command
```sql
SELECT field_1 FROM public.my_table;
```
output
```
 field_1
---------
 hello
(1 row)
```

> Including the schema/namespace prefix with the table name forms a _fully qualified_ table name. Dot notation is used to connect the schema/namespace prefix to the table name.

---

Command

```psql
\q
```
```bash
du $PGDATA --exclude='/proc' -sh
```
Output
```
50M     /var/lib/postgresql/data
```

> Quit Postgres with meta-command `\q` to drop back into the Bash shell and check the size of `$PGDATA`. Observe the size of `$PGDATA` growing from `42M` to `50M` with the addition of a database and data.

### Dismantle the demo database

Command
```bash
psql -U postgres
```
```psql
\c mydb
```
```sql
ALTER TABLE my_table DROP COLUMN field_1;
```
output
```
ALTER TABLE
```
---

> Reconnect to Postgres, connect to the `mydb` demo database, and `DROP` a column.

Command
```sql
SELECT field_1 FROM my_table;
```
output
```
ERROR:  column "field_1" does not exist
LINE 1: SELECT field_1 FROM my_table;
               ^
```

> After dropping the `field_1` column tying to select it produces an error. Note that Postgres will highlight the offending part of the input by line number and the caret `^` to show where the bad input begins.

---

Command
```sql
DROP TABLE my_table;
```
output
```
DROP TABLE
```
---

Command
```psql
\dt
```
output
```
Did not find any relations.
```
---

Command
```psql
\c postgres
```
output
```
You are now connected to database "postgres" as user "postgres".
```

> Our next step will be dropping the database, but dropping a database while connected to it will produce an error: `ERROR:  cannot drop the currently open database`.
>
> There is no dedicated "disconnect" command that leaves you in an unattached shell. \c postgres: Connects you to the default postgres maintenance database. (Recall earlier comments about the purpose of the default `postgres` database.)

---

Command
```sql
DROP DATABASE mydb;
```
output
```
DROP DATABASE
```
---

Command
```psql
\list
```
output
```
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

---

Command
```psql
\q
```
```bash
du $PGDATA --exclude='/proc' -sh
```
Output
```
42M     /var/lib/postgresql/data
```

> Quit Postgres and return to the Bash shell, check the size of `$PGDATA` and confirm it has _decreased_ in size after dropping the demo database. Note, if the command `du $PGDATA --exclude='/proc' -s` (dropping the `-h` flag for _human-readable_ memory units, we would have seen before/after sizes in kilobytes of `42672` and `42684`, confirming the size decreased after dropping the database, but there are still some remaining artifacts using space.

---

## Logging

> Logs provide a ground-truth record of all activity, making them essential for debugging errors, auditing behavior, and analyzing performance.
>
> By default, the official Docker PostgreSQL image does not write logs to a file within `$PGDATA/logs`. Instead, it sends all log output to stderr, which is captured by the Docker daemon.
>
> Postgres only writes to files if the logging_collector is specifically enabled. By default, this is set to off in the Docker image to allow Docker's native logging to work.
>
> Run `docker logs -f <container_name>` to see a real-time stream of all queries.

Command

```bash
docker logs postgres-dev-cont
```
Output
```text
The files belonging to this database system will be owned by user "postgres".
This user must also own the server process.

The database cluster will be initialized with locale "en_US.utf8".
The default database encoding has accordingly been set to "UTF8".
The default text search configuration will be set to "english".

Data page checksums are disabled.

fixing permissions on existing directory /var/lib/postgresql/data ... ok
creating subdirectories ... ok
selecting dynamic shared memory implementation ... posix
selecting default max_connections ... 100
selecting default shared_buffers ... 128MB
selecting default time zone ... Etc/UTC
creating configuration files ... ok
running bootstrap script ... ok
performing post-bootstrap initialization ... ok
initdb: warning: enabling "trust" authentication for local connections
You can change this by editing pg_hba.conf or using the option -A, or
--auth-local and --auth-host, the next time you run initdb.
syncing data to disk ... ok


Success. You can now start the database server using:

    pg_ctl -D /var/lib/postgresql/data -l logfile start

waiting for server to start....2026-04-28 22:59:26.172 UTC [49] LOG:  starting PostgreSQL 14.22 (Debian 14.22-1.pgdg13+1) on x86_64-pc-linux-gnu, compiled by gcc (Debian 14.2.0-19) 14.2.0, 64-bit
2026-04-28 22:59:26.182 UTC [49] LOG:  listening on Unix socket "/var/run/postgresql/.s.PGSQL.5432"
2026-04-28 22:59:26.212 UTC [50] LOG:  database system was shut down at 2026-04-28 22:59:25 UTC
2026-04-28 22:59:26.223 UTC [49] LOG:  database system is ready to accept connections
 done
server started
2026-04-28 22:59:26.431 UTC [59] LOG:  statement: SELECT 1 FROM pg_database WHERE datname = 'postgres' ;

/usr/local/bin/docker-entrypoint.sh: ignoring /docker-entrypoint-initdb.d/*

2026-04-28 22:59:26.436 UTC [49] LOG:  received fast shutdown request
waiting for server to shut down....2026-04-28 22:59:26.443 UTC [49] LOG:  aborting any active transactions
2026-04-28 22:59:26.448 UTC [49] LOG:  background worker "logical replication launcher" (PID 56) exited with exit code 1
2026-04-28 22:59:26.448 UTC [51] LOG:  shutting down
2026-04-28 22:59:26.499 UTC [49] LOG:  database system is shut down
 done
server stopped

PostgreSQL init process complete; ready for start up.

2026-04-28 22:59:26.584 UTC [1] LOG:  starting PostgreSQL 14.22 (Debian 14.22-1.pgdg13+1) on x86_64-pc-linux-gnu, compiled by gcc (Debian 14.2.0-19) 14.2.0, 64-bit
2026-04-28 22:59:26.585 UTC [1] LOG:  listening on IPv4 address "0.0.0.0", port 5432
2026-04-28 22:59:26.585 UTC [1] LOG:  listening on IPv6 address "::", port 5432
2026-04-28 22:59:26.594 UTC [1] LOG:  listening on Unix socket "/var/run/postgresql/.s.PGSQL.5432"
2026-04-28 22:59:26.607 UTC [62] LOG:  database system was shut down at 2026-04-28 22:59:26 UTC
2026-04-28 22:59:26.619 UTC [1] LOG:  database system is ready to accept connections
2026-04-28 23:03:06.339 UTC [76] LOG:  statement: CREATE DATABASE mydb;
2026-04-28 23:03:27.818 UTC [80] LOG:  statement: CREATE TABLE my_table ();
2026-04-28 23:03:39.394 UTC [80] LOG:  statement: ALTER TABLE my_table ADD COLUMN field_1 text;
2026-04-28 23:03:52.345 UTC [80] LOG:  statement: SELECT field_1 FROM my_table;
2026-04-28 23:04:01.562 UTC [80] LOG:  statement: INSERT INTO my_table (field_1) VALUES ('hello');
2026-04-28 23:04:11.573 UTC [80] LOG:  statement: SELECT field_1 FROM my_table;
2026-04-28 23:04:21.364 UTC [80] LOG:  statement: SELECT field_1 FROM public.my_table;
2026-04-28 23:04:28.622 UTC [80] LOG:  statement: ALTER TABLE my_table DROP COLUMN field_1;
2026-04-28 23:04:35.054 UTC [80] LOG:  statement: SELECT field_1 FROM my_table;
2026-04-28 23:04:35.054 UTC [80] ERROR:  column "field_1" does not exist at character 8
2026-04-28 23:04:35.054 UTC [80] STATEMENT:  SELECT field_1 FROM my_table;
2026-04-28 23:04:50.986 UTC [80] LOG:  statement: DROP TABLE my_table;
2026-04-28 23:05:02.507 UTC [80] LOG:  statement: DROP DATABASE mydb;
2026-04-28 23:05:02.507 UTC [80] ERROR:  cannot drop the currently open database
2026-04-28 23:05:02.507 UTC [80] STATEMENT:  DROP DATABASE mydb;
2026-04-28 23:05:19.899 UTC [84] LOG:  statement: DROP DATABASE mydb;
```

## Summary of SQL commands used

When all commentary and output examples are removed we can easily see only a handful of SQL commands were used in this demo. Yet we examined in depth how those commands at the SQL layer interact with the Linux system and Postgres engine layers. This provides a strong foundation upon which we can continue to build our SQL knowledge.

### Create

* `CREATE DATABASE mydb;`
* `CREATE TABLE my_table ();`
* `ALTER TABLE my_table ADD COLUMN field_1 text;`
* `INSERT INTO my_table (field_1) VALUES ('hello');`

### Read 

* `SELECT field_1 FROM my_table;`

### Delete

* `DROP TABLE my_table;`
* `DROP DATABASE mydb;`

### Postgres meta-commands used

* `\list` list databases
* `\c <db>` connect to a database
* `\dt` list tables
* `\d <table>` describe a table
* `\dn` list namespaces/schemas
* `\q` quit psql client

---

Lab 1 establishes the full system—from container to query execution. Future labs will build on this foundation, focusing more on data modeling and query behavior within an already-understood environment.

---
