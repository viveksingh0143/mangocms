**Findings**

- **Critical: public platform admin registration creates admin users.**  
  [router.ex](/Users/viveksingh/development/mangocms/lib/mangocms_web/router.ex:58) exposes `/platform/admin/register`, [auth_controller.ex](/Users/viveksingh/development/mangocms/lib/mangocms_web/controllers/auth_controller.ex:260) calls `Accounts.register_platform_user/1`, and [accounts/user.ex](/Users/viveksingh/development/mangocms/lib/mangocms/accounts/user.ex:30) defaults role to `"admin"`. Anyone who can reach the platform host can create a platform admin account unless this route is otherwise blocked externally.

- **Critical: public tenant admin registration creates tenant admin users.**  
  [router.ex](/Users/viveksingh/development/mangocms/lib/mangocms_web/router.ex:99) exposes `/admin/register` on tenant hosts, and [auth_controller.ex](/Users/viveksingh/development/mangocms/lib/mangocms_web/controllers/auth_controller.ex:262) registers role `"admin"`. This means anyone with a tenant domain can self-register as tenant admin. This should be invite-only, first-owner-only, disabled after bootstrap, or platform-admin controlled.

- **High: tenant repo migrations run on every tenant DB access.**  
  [tenant_repo_manager.ex](/Users/viveksingh/development/mangocms/lib/mangocms/tenant_repo_manager.ex:55) runs `TenantMigrator.migrate_repo!` by default every time `with_repo/3` is called. This affects login/session fetches, product CRUD, profile updates, etc. It will add latency and can create lock contention. Migrations should run at tenant creation, deploy/startup task, or once-per-process with a cache flag.

- **High: SQLite backup is unsafe with WAL mode.**  
  SQLite is configured with WAL, but [backup_worker.ex](/Users/viveksingh/development/mangocms/lib/mangocms/workers/backup_worker.ex:22) copies only `tenant.db`. With WAL, recent writes may live in `tenant.db-wal`, so this can produce stale or inconsistent backups. Use SQLite backup API/checkpoint plus copy, or copy `.db`, `.db-wal`, `.db-shm` safely while quiesced.

- **High: SSO ID token claims are decoded but not verified.**  
  [sso.ex](/Users/viveksingh/development/mangocms/lib/mangocms/accounts/sso.ex:133) decodes JWT payloads without verifying signature, issuer, audience, expiry, or nonce. Also [oauth_controller.ex](/Users/viveksingh/development/mangocms/lib/mangocms_web/controllers/oauth_controller.ex:12) creates nonce but I don’t see it checked against returned claims. Use provider JWKS/OIDC verification.

- **Medium: tenant slug edits can silently move tenant storage paths.**  
  [tenant.ex](/Users/viveksingh/development/mangocms/lib/mangocms/platform/tenant.ex:193) recalculates `db_path` and `storage_path` from slug on every changeset. Editing a slug can point the tenant at a new empty DB path without moving data. Slug/storage path should be immutable after creation unless using an explicit migration/rename operation.

- **Medium: tenant repos are never evicted.**  
  [tenant_repo_manager.ex](/Users/viveksingh/development/mangocms/lib/mangocms/tenant_repo_manager.ex:34) dynamically starts one repo per tenant and keeps it running. For many small tenants, this can accumulate file handles, memory, and Postgres connections. Fine for a small count, but add lifecycle/idle eviction before scaling.

**Good News**
The revert puts you back closer to the cheaper, simpler model: one tenant DB adapter for the tenant layer. That is the right direction for low-cost small/medium sites. The biggest blockers now are not the adapter choice; they are public admin registration, migration-on-every-access, and backup correctness.
