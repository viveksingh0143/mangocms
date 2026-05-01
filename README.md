# 🥭 MangoCMS

A **multi-tenant, plan-driven CMS platform** built with Phoenix (Elixir), designed for scalability, strict tenant isolation, and local-first development.

---

# 🎯 Objective

MangoCMS enables a single platform to host **multiple independent websites (tenants)**, each governed by a shared **Plan system**.

- Multi-tenant architecture
- Strong data isolation
- Many-to-one Plan model
- Local-first, cloud-ready

---

# 🧠 Core Architecture

## Tenant–Plan Relationship

```
Plan (1) ────< Tenant (N)
```

### Plan

Defines:

- Limits (pages, storage, API usage)
- Features (SEO, analytics, etc.)

### Tenant

- Belongs to exactly one Plan
- Has its own domain
- Has isolated storage and database

---

# 🏗 System Overview

## 1. Tenant Isolation

Each tenant has:

```
/data/tenants/{tenant_id}/
```

- Separate storage
- Independent database (SQLite/JSON)
- No cross-tenant access

---

## 2. Platform Registry (Meta DB)

Central database (`platform.db`) stores:

- Tenants
- Plans
- Domain mappings

---

## 3. Tenant Resolution Flow (Critical Path)

Every request:

1. Extract domain
2. Resolve tenant:
   - Redis (cache)
   - Fallback → SQLite

3. Load:
   - Tenant
   - Plan

4. Attach to request context

---

## 4. Plan Enforcement

Handled via middleware (Plug):

- Page limits
- Storage limits
- Feature access

---

## 5. Storage Strategy

| Layer       | Technology    |
| ----------- | ------------- |
| Platform DB | SQLite        |
| Tenant DB   | SQLite / JSON |
| Media       | Local FS      |

---

## 6. Caching Strategy

- Phase 1 → Redis
- Future → Go sidecar (high-performance cache)

---

## 7. Scalability Goals

- Thousands of tenants
- Fast domain resolution
- Low-latency via caching

---

## 8. Security

- Strict tenant isolation
- Domain-based routing
- No shared tenant state

---

## 9. Backup & Recovery

- Daily backups via Oban
- Tenant-level restore

---

## 🧱 Project Structure

```
lib/mangocms/
  platform/
    plan.ex
    tenant.ex
    tenant_resolver_plug.ex
    plan_guard_plug.ex

  content/
  media/
  api/
  admin/
```

---

# ⚙️ Tech Stack

- **Backend:** Phoenix (Elixir)
- **Database:** SQLite (`exqlite`)
- **Cache:** Redis (`redix`)
- **Jobs:** Oban
- **Storage:** Local FS (Hetzner later)

---

# 🚀 Phase Roadmap

## Phase 0 — Design

- Define Tenant + Plan model
- Setup Platform context
- Finalize storage and caching strategy

## Phase 1 — Foundation

- Tenant resolution via domain
- Plan attachment
- Redis caching
- Basic enforcement

## Phase 2 — Admin CMS

- Dashboard (LiveView)
- Content management
- User roles

## Phase 3 — Public + SEO

- SSR pages
- Search (SQLite FTS5)
- Sitemap, metadata

---

# 🚦 Non-Goals (Phase 1)

- Billing system
- Advanced RBAC
- Multi-region deployment
- Analytics

---

# 🧭 Guiding Principles

- Never mix tenant data
- Always resolve tenant first
- Cache before DB
- Keep platform and tenant concerns separate
- Avoid hardcoding plan limits

---

# ✅ Phase 1 Success Criteria

- Domain resolves to correct tenant
- Plan is attached to request
- Isolation is enforced
- System runs locally end-to-end

---

# 🛠 Getting Started

```bash
mix deps.get
mix ecto.setup
mix phx.server
```

---

# 📌 Future Extensions

- Billing system
- Usage tracking
- Feature flags
- Mobile API
- CDN/media optimization

---

# 👨‍💻 Author Notes

This system is designed with **platform-first thinking**, ensuring:

- Clean separation of concerns
- High scalability
- Easy evolution into SaaS

---
