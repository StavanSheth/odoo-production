# Backup and Restore Procedures

## Anatomy of an Odoo Backup
An Odoo backup is **not** just a SQL dump. A complete backup requires:
1. **PostgreSQL Database**: Tables, relational records, accounting entries, configuration.
2. **Odoo Filestore**: Documents, uploaded PDF invoices, customer signatures, product images stored in `/var/lib/odoo/filestore`.

---

## 1. Creating a Backup
Execute:
```bash
bash scripts/backup.sh
```
This produces an archive in `backups/odoo_backup_YYYYMMDD_HHMMSS.tar.gz` containing:
* `database.dump` (compressed pg_dump format)
* `filestore.tar.gz` (filestore folder)
* `manifest.json` (metadata snapshot)

Backups older than 14 days are automatically pruned.

---

## 2. Restoring a Backup
```bash
bash scripts/restore.sh backups/odoo_backup_YYYYMMDD_HHMMSS.tar.gz
```
The script will ask for explicit confirmation (`RESTORE`) before stopping the application server, recreating the database, restoring records, unpacking attachments, and restarting services.

