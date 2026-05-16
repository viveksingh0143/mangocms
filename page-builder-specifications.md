# System Specification & Implementation Prompt: MangoCMS Page Builder

## Context & Tech Stack

You are an expert Elixir/Phoenix engineer building a visual Page Builder for a Content Management System named **MangoCMS**.

- **Backend:** Elixir 1.18, OTP, Phoenix 1.7+ (LiveView 1.1), Ecto SQL, SQLite3 (`ecto_sqlite3`).
- **Frontend:** Tailwind CSS v4, daisyUI (component framework), and Alpine.js (for client-side editor interactions).

---

## 1. Core Architecture & Design Patterns

### A. The Core Component + Wrapper Pattern

The UI must share a single file system codebase for components to maintain DRY principles, splitting execution logic between the Admin Canvas and the Public Viewport:

1. **Presentation Elements (`lib/mangocms_web/components/page_elements.ex`):** Pure, stateless functional components (`Phoenix.Component`) rendering raw markup and consuming a standardized map of attributes and categorized classes.
2. **Canvas Interactive Wrapper (`lib/mangocms_web/live/admin/editor_canvas.ex`):** A higher-order component utilizing LiveView slots to wrap components inside the editor. It injects absolute-positioned UI overlays, hover states, dashed outlines, component handles, and Phoenix action triggers (`phx-click="select_element"`). Each container component declares a `@accepted_types` module attribute; drop events are validated against it and rejected with a flash error on mismatch — never silently corrupting the tree.
3. **Public Router Target (`lib/mangocms_web/live/public/page_live.ex`):** Recursively parses the JSON tree data structure to execute clean HTML outputs devoid of administrative scripts or event hooks. Draft pages must return a 404 or redirect — never rendered publicly.

### B. Input Interactivity (Avoiding LiveView DOM Diff Battles)

To prevent Phoenix LiveView's patch algorithm from disrupting the cursor position during raw text editing, any block utilizing `contenteditable` must be isolated:

- Use a client-side JavaScript Hook (`phx-hook`) combined with **Alpine.js**, with a strict ownership boundary: **the Hook owns the `pushEvent` bridge to LiveView; Alpine owns only visual/UI state** (toolbar visibility, dropdown open/close). Neither layer touches data owned by the other.
- The text edit must state-track changes completely in the browser DOM.
- Only update the Elixir state machine via a pushed event (`this.pushEvent("update_text_property", ...)`), bound to a `phx-blur` event or heavy debounce delay when the component loses focus.

---

## 2. Database & Data Structure Layout

### A. Ecto Schema Configuration

The page layout must be modeled as an **Abstract Syntax Tree (AST)** nested block structure stored within a single JSON column for flat, single-query reading efficiency.

```elixir
# Pages Table
schema "pages" do
  field :title, :string
  field :slug, :string
  field :status, Ecto.Enum, values: [:draft, :published, :archived], default: :draft
  field :published_at, :utc_datetime
  field :content_tree, {:array, :map}, default: []
  field :content_tree_version, :integer, default: 1  # optimistic locking — not version history
  timestamps()
end

# Global Sections Table (Synced Blocks across multiple pages)
schema "global_sections" do
  field :name, :string
  field :content_tree, {:array, :map}, default: []
  timestamps()
end

# Page Versions Table — immutable append-only audit ledger
schema "page_versions" do
  field :content_tree, {:array, :map}
  field :version_number, :integer         # monotonically incrementing per page
  field :label, :string                   # optional: user-supplied e.g. "Before hero redesign"
  field :change_summary, :string          # optional: auto-generated or manual description
  field :snapshot_type, Ecto.Enum,
        values: [:auto, :manual, :publish_checkpoint],
        default: :auto
  field :restored_from, :integer          # if this is a restore, track the source version number

  belongs_to :page, MangoCMS.Page
  belongs_to :created_by, MangoCMS.AdminUser

  timestamps(updated_at: false)           # versions are immutable — no updated_at
end

# Global Section Versions Table — mirrors page_versions for global_sections
schema "global_section_versions" do
  field :content_tree, {:array, :map}
  field :version_number, :integer
  field :label, :string
  field :change_summary, :string
  field :snapshot_type, Ecto.Enum,
        values: [:auto, :manual, :publish_checkpoint],
        default: :auto
  field :restored_from, :integer

  belongs_to :global_section, MangoCMS.GlobalSection
  belongs_to :created_by, MangoCMS.AdminUser

  timestamps(updated_at: false)
end
```

> **Critical distinctions:**
>
> - `content_tree_version` on `pages` is an **optimistic lock counter only** — it prevents concurrent tab overwrites and is bumped on every save. It is not version history.
> - `page_versions` is the **immutable audit ledger**. The `pages` table is always the live working copy. These are separate concerns and must never be conflated.
> - Use `{:array, :map}` — not `:map` — for all `content_tree` fields. With `ecto_sqlite3`, `:map` expects a JSON object `{}` and will reject a root-level array `[]`.

### B. Standard Component Schema Object (JSON Tree Specification)

Every object inside the `content_tree` list must conform to this schema blueprint:

```json
{
  "type": "component",
  "name": "button",
  "id": "unique_nanoid_or_uuid",
  "path": "root.sect_abc.row_xyz.col_1",
  "props": {
    "text": "Get Started",
    "href": "/signup",
    "target": "_self"
  },
  "classes": {
    "display": "inline-flex items-center justify-center",
    "daisy_ui": "btn btn-primary btn-md",
    "padding": "px-6 py-2",
    "margin": "mt-4",
    "custom": ""
  }
}
```

> **Note:** The `"path"` field is a materialized path string (dot-separated ancestor IDs). It allows O(1) node location without full tree traversal, making `move_node` and reparenting dramatically simpler. It must be recomputed and updated on every mutation that changes tree structure.

### C. Snapshot Strategy

Snapshots must be triggered on meaningful boundaries only — never on every keystroke or auto-save tick, as that produces noise with no restore value:

| `snapshot_type`       | When triggered                                               |
| --------------------- | ------------------------------------------------------------ |
| `:auto`               | Every explicit user-initiated Save action                    |
| `:manual`             | User clicks "Save Version" with an optional label            |
| `:publish_checkpoint` | Automatically on every `draft → published` status transition |

`:publish_checkpoint` entries provide a clean "what went live and when" audit trail and must never be pruned. `:auto` versions are capped at the last 50 per page; `:manual` versions are retained indefinitely.

---

## 3. UI Layout & Features Required

The user interface is a classic **Trifold Studio Layout**:

### Left Sidebar: The Asset Foundry & Tree Layer

- **Search Bar:** Filters components instantly.
- **Behavioral Groupings List:** Accordion-style container containing:
  - _Layout Blocks:_ Section, Row, Column layouts (1:1, 2:1, 3:1, 4:1, 3:2 ratios).
  - _Typography:_ Headings (H1–H6), Paragraph, Blockquotes.
  - _Media:_ Image, Video wrapper.
  - _Interactive:_ Button, Anchor Link, Simple Dynamic Form.
  - _Global Sections:_ Fetched items dynamically populated from the `global_sections` database.
- **Layers Tree View:** A structured DOM outline list mapping nested depths (e.g., `Section > Row > Column 2 > Button`). Clicking an outline layer updates the active component node on the main canvas.

### Center Canvas: Responsive Drop Zone Engine

- **Viewport Toolbar:** Switch modes between Desktop (100%), Tablet (768px), and Mobile (375px).
- **The 4-Tier Box Container Tree Layout:**
  1. **Section Wrapper:** Full-width layout outer wrapper blocks.
  2. **Row Grid:** Maximum inner constraint boundaries with adjustable column allocations and spacing gutter inputs.
  3. **Column Containers:** Grid target drops where specific layout sizing handles are processed.
  4. **Component Blocks:** Final nested content nodes.
- **Drop Indicator:** Visual CSS hints indicating active placement positions above/below an element during drag-and-drop sequencing.
- **Undo/Redo Stack:** Every mutation pushes the previous `content_tree` onto a history stack (capped at 50 entries) stored in the LiveView socket assigns. Ctrl+Z / Ctrl+Shift+Z traverse the stack entirely in-socket — no database reads required.

```elixir
# In the LiveView socket assigns
assign(socket,
  history: [initial_tree],
  history_index: 0
)
```

- **Node Clipboard:** A `clipboard` socket assign holds a deep-copied subtree node. Right-click → Copy on any node; Paste targets any compatible container. Zero backend cost.

### Right Sidebar: Contextual Control Inspector

Updates dynamically matching the attributes of the active element ID:

- **Typography/Button Controls:** Text, URL fields, navigation target tabs (`_self` vs `_blank`).
- **Media Element Management:** Includes an **Asset Library Modal Picker** allowing local file system uploads or previous media gallery file grid selection.
- **The Tailwind Utility Grid Modifier:** Inputs mapped directly to the active component's `classes` keys (`padding`, `margin`, `daisy_ui`, `custom`) enabling atomic class updates without breaking global styles.
- **Global Link Unshackler:** A dedicated toggle to unlink an asset from a `global_section` pattern, duplicating the instance configuration locally. Unlinked nodes must have `"unlinked": true` set in their `props` so the propagation worker skips them.
- **Version History Panel:** A scrollable list of `page_versions` records showing `version_number`, `inserted_at`, `created_by`, `snapshot_type` badge, and optional label. `:publish_checkpoint` entries are visually distinguished (e.g. a green "Published" badge). Each entry has a **Restore** button behind a confirmation step: _"This will replace the current draft. Your current state will be saved first."_
- **Diff Indicator:** On hover of a version entry, display a computed summary (e.g. "3 blocks added, 1 removed") derived by comparing node IDs between the two trees.

---

## 4. Module Responsibilities

### `MangoCMS.ContentTree` — Pure Functional AST Module

All tree mutation logic must live in a dedicated module with **zero Phoenix/Ecto imports**. This keeps mutations trivially unit-testable without spinning up a LiveView process.

```elixir
defmodule MangoCMS.ContentTree do
  @moduledoc "Pure functional AST manipulations on nested block trees."

  @spec find_node(tree :: list(), id :: String.t()) :: map() | nil
  def find_node(tree, id), do: ...

  @spec update_node_props(tree :: list(), id :: String.t(), props :: map()) :: list()
  def update_node_props(tree, id, props), do: ...

  @spec update_node_classes(tree :: list(), id :: String.t(), classes :: map()) :: list()
  def update_node_classes(tree, id, classes), do: ...

  @spec move_node(tree :: list(), node_id :: String.t(), target_id :: String.t(), position :: :before | :after | :into) :: list()
  def move_node(tree, node_id, target_id, position), do: ...

  @spec delete_node(tree :: list(), id :: String.t()) :: list()
  def delete_node(tree, id), do: ...

  @spec diff_trees(tree_a :: list(), tree_b :: list()) :: map()
  def diff_trees(tree_a, tree_b), do: ...
  # Returns %{added: [...ids], removed: [...ids], changed: [...ids]}
  # Used by the Version History diff indicator in the right sidebar.
end
```

### `MangoCMS.Pages` — Context Module

All database operations for pages and their versions must route through this context. No raw `Repo` calls outside it.

```elixir
defmodule MangoCMS.Pages do

  @doc "Creates an auto snapshot, then restores the page to the given version's content tree."
  def restore_page_to_version(page, version) do
    Repo.transaction(fn ->
      # 1. Snapshot current state before overwriting (reversible restore)
      {:ok, _} = create_page_version(page, :auto, "Pre-restore snapshot")

      # 2. Apply the historical tree
      page
      |> Page.changeset(%{
          content_tree: version.content_tree,
          content_tree_version: page.content_tree_version + 1,
          restored_from: version.version_number
         })
      |> Repo.update!()
    end)
  end

  @doc """
  Persists a version snapshot. snapshot_type is one of :auto | :manual | :publish_checkpoint.
  Called before every save, on publish, and before every restore.
  """
  def create_page_version(page, snapshot_type, label \\ nil) do
    ...
  end

  @doc "Checks content_tree_version against DB before writing. Returns {:error, :stale} on conflict."
  def save_page_with_lock(page, attrs, socket_version) do
    ...
  end
end
```

### Oban Workers

```elixir
defmodule MangoCMS.Workers.PropagateGlobalSection do
  @moduledoc """
  Triggered after a global_section is updated.
  Re-embeds the updated subtree into all pages referencing it.
  Skips nodes where props["unlinked"] == true (locally unshackled copies).
  Bumps content_tree_version on each affected page to invalidate stale open tabs.
  """
  use Oban.Worker, queue: :default

  @impl true
  def perform(%{args: %{"global_section_id" => id}}) do
    ...
  end
end

defmodule MangoCMS.Workers.PrunePageVersions do
  @moduledoc """
  Deletes :auto versions beyond the 50-entry retention limit per page.
  Never deletes :manual or :publish_checkpoint versions.
  Runs at most once per hour per page (unique: [period: 3600]).
  """
  use Oban.Worker, queue: :default, unique: [period: 3600]

  @auto_retention_limit 50

  @impl true
  def perform(%{args: %{"page_id" => page_id}}) do
    ...
  end
end
```

---

## 5. Implementation Milestones

Implement in this sequence. Each milestone must be stable before the next begins.

### Milestone 1 — `MangoCMS.ContentTree` + Tests

Implement and fully unit-test all tree mutation and diff functions. No UI or Ecto dependency. Validate `find_node`, `update_node_props`, `update_node_classes`, `move_node`, `delete_node`, and `diff_trees` against fixture trees before any rendering work begins.

### Milestone 2 — Ecto Schemas + Migrations

Create all schemas (`pages`, `global_sections`, `page_versions`, `global_section_versions`) and their migrations. Implement the `MangoCMS.Pages` context with `create_page_version`, `restore_page_to_version`, and `save_page_with_lock`. Write context-level tests covering the restore transaction and the optimistic lock conflict path.

### Milestone 3 — Parser / Renderer Engine

Write the Elixir recursive module that maps the nested map structure into safe, efficient HTML using LiveView functional component syntax. The public `PageLive` renderer calls this. It must produce zero admin markup and must 404 on non-published slugs.

### Milestone 4 — LiveView Shell + Drag-and-Drop

Wire the trifold layout, socket assigns (`history`, `history_index`, `clipboard`, `selected_id`, `current_version`), and drag-and-drop drop zone events. Integrate `ContentTree` mutations into LiveView event handlers. Implement optimistic lock detection on save: compare `content_tree_version` in the socket against the DB value before writing; flash a warning and halt if stale.

### Milestone 5 — Version History UI

Build the Version History panel in the right sidebar. Wire restore flow through `MangoCMS.Pages.restore_page_to_version/2`. Surface the `diff_trees` output as a hover tooltip on each version entry.

### Milestone 6 — Alpine.js Hook (contenteditable bridge)

Implement the JavaScript Hook last, when the rest of the system is stable. The Hook pushes `update_text_property` events to LiveView on blur/debounce. Alpine handles only local UI state (toolbar show/hide). No Alpine data must mirror LiveView assigns.

---

## 6. Global Constraints

- All Elixir modules must include `@moduledoc`, `@doc`, and `@spec` annotations.
- Section comments must clearly delineate responsibility boundaries within files.
- `content_tree_version` must be incremented on every successful page save and checked before writes.
- The `status` field transitions (`draft → published`, `published → archived`) must be explicit context functions — not raw Ecto updates — to allow future FSM integration.
- `page_versions` and `global_section_versions` records are **immutable**. No `update` calls ever target these tables. Restore is a write to `pages`, not a mutation of version history.
- The `MangoCMS.ContentTree` module must remain free of all Phoenix, LiveView, and Ecto imports. It is a pure data transformation layer and must be testable in isolation.
