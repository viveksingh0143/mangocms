# Section Builder Migration + Complete Component Library

---

## Alpine.js Context

Alpine.js v3.14.9 is installed at `assets/vendor/alpine.min.js` (ESM module).

### Setup (`assets/js/app.js`)

- Imported as: `import Alpine from "../vendor/alpine.min.js"`
- Exposed globally: `window.Alpine = Alpine`
- Started **before** `liveSocket.connect()`: `Alpine.start()`
- `AlpineInit` LiveView hook registered in liveSocket hooks:

```js
const AlpineInit = {
  mounted()  { window.Alpine?.destroyTree(this.el); window.Alpine?.initTree(this.el) },
  updated()  { window.Alpine?.destroyTree(this.el); window.Alpine?.initTree(this.el) },
}
```

### Why `AlpineInit` is Required

LiveView patches the DOM on every prop/variant change. Alpine does not
auto-reinitialize elements it did not see on first paint. Any container
LiveView can patch must carry `id="stable-id" phx-hook="AlpineInit"` so
Alpine is destroyed + reinited after each patch.

### x-data Encoding Rule — Always Use `Jason.encode!`

Never interpolate string values into x-data with `'#{value}'`.
Use `Jason.encode!` so Alpine receives valid JSON and strings are properly escaped.

```elixir
# BAD
x-data={"{ open: '#{@props["default_open"]}' }"}
x-bind:class={"active === '#{tab.id}' && 'tab-active'"}
x-on:click={"active = '#{tab.id}'"}

# GOOD
x-data={Jason.encode!(%{"open" => @props["default_open"]})}
x-bind:class={"active === #{Jason.encode!(tab.id)} && 'tab-active'"}
x-on:click={"active = #{Jason.encode!(tab.id)}"}
```

Alpine accepts JSON objects as `x-data` values natively.

### Alpine vs LiveView Boundary

| Responsibility | Owner |
|---|---|
| Open/closed, active tab, carousel index, hover animation, theme | Alpine |
| Prop values, variant selection, content tree | LiveView |

- Never read LiveView assigns inside Alpine `x-data` at runtime — bake values into x-data at render time using `Jason.encode!`
- Do **not** put `phx-click` and `x-on:click` on the same element for the same action

### Existing Components with Alpine

`accordion`, `carousel`, `collapse`, `countdown`, `diff`, `dock`, `drawer`,
`dropdown`, `fab`, `filter`, `hero`, `hover_3d_card`, `hover_gallery`, `menu`,
`modal`, `navbar`, `swap`, `tabs`, `text_rotate`, `theme_controller`, `calendar`

Each declares Alpine metadata in its manifest:

```elixir
alpine: %{component: "accordion", owns: ["open"]}
```

### New Components Requiring Alpine

| Component | Alpine state | Trigger |
|---|---|---|
| `gallery` | `open`, `active_index` | click image to open lightbox |
| `banner` | `dismissed` | click dismiss button |
| `notification_bar` | `dismissed` | click dismiss button |
| `copy_button` | `copied` | click copies to `navigator.clipboard`, resets after 2s |
| `read_more` | `expanded` | click toggles truncated / full text |
| `scroll_to_top` | `visible` | `window` scroll listener on `x-init` |
| `cookie_banner` | `dismissed` | accept/decline, persisted to `localStorage` |
| `table_of_contents` | `headings` | `x-init` scans parent DOM for heading elements |
| `faq_section` | `open` | click accordion row (same pattern as `accordion`) |

### Alpine x-data Patterns for New Components

```elixir
# copy_button
x-data={Jason.encode!(%{"copied" => false})}
x-on:click={"navigator.clipboard.writeText(#{Jason.encode!(@props["value"] || "")}).then(() => { copied = true; setTimeout(() => copied = false, 2000) })"}

# read_more
x-data={Jason.encode!(%{"expanded" => false})}
x-bind:class={"expanded ? '' : 'line-clamp-#{@props["lines"] || 3}'"}

# scroll_to_top
x-data={Jason.encode!(%{"visible" => false})}
x-init={"window.addEventListener('scroll', () => { visible = window.scrollY > #{Jason.encode!(@props["threshold_px"] || 300)} })"}

# cookie_banner
x-data={"{ dismissed: localStorage.getItem('cookie_consent') === 'true' }"}
x-show="!dismissed"
x-on:accept={"dismissed = true; localStorage.setItem('cookie_consent', 'true')"}

# gallery lightbox
x-data={Jason.encode!(%{"open" => false, "active" => 0})}
x-on:keydown.escape.window="open = false"

# banner / notification_bar dismiss
x-data={Jason.encode!(%{"dismissed" => false})}
x-show="!dismissed"

# faq_section (same as accordion pattern)
x-data={Jason.encode!(%{"open" => ""})}
x-bind:class={"open === #{Jason.encode!(item.id)} && 'collapse-open'"}
x-on:click={"open = open === #{Jason.encode!(item.id)} ? '' : #{Jason.encode!(item.id)}"}
```

### Card Grid Thumbnail Rule

Component grid cards **must** use `<div phx-click={JS.patch(...)}>` — **not** `<.link>`.

> Reason: `.link` renders as `<a>`. Components that themselves render `<a>` tags
> (button, breadcrumbs, navbar, pagination …) create invalid nested anchors.
> Browsers eject the inner content, leaving empty cards.

---

## Project Context

MangoCMS is a Phoenix 1.8 / LiveView multi-tenant CMS with a manifest-driven builder system. Every UI component has:

1. **Manifest** at `lib/mangocms_web/builder/manifests/<name>.ex` — defines `name`, `label`, `group`, `default_props`, `default_classes`, `variants`, `fields` (inspector), `slots`, `accepted_children`, `alpine` metadata
2. **Renderer** function in `lib/mangocms_web/components/builder_library/<group>_components.ex` — pure Phoenix function component, receives `node` and `context` assigns
3. **Registration** in `lib/mangocms_web/builder/registry.ex`

The UI Library at `/admin/ui-library` and `/platform/admin/ui-library` renders every registered component as a browsable, live-preview card.

The page/section builder at `/admin/pages/:id/builder` currently uses its **own older component block system** that predates the manifest library.

---

## Key Files to Read Before Starting

| File | Purpose |
|---|---|
| `lib/mangocms_web/builder/manifest.ex` | `@behaviour` spec |
| `lib/mangocms_web/builder/field.ex` | Field DSL |
| `lib/mangocms_web/builder/registry.ex` | Registration list |
| `lib/mangocms_web/builder/renderer.ex` | Node rendering |
| `lib/mangocms_web/builder/manifests/button.ex` | Reference manifest |
| `lib/mangocms_web/builder/manifests/accordion.ex` | Reference — Alpine + slots |
| `lib/mangocms_web/builder/manifests/hero.ex` | Reference — slots + accepted_children |
| `lib/mangocms_web/components/builder_library/action_components.ex` | Reference renderer |
| `lib/mangocms_web/live/tenant/admin/ui_library_live/index.ex` | UI Library LiveView |
| All section/page builder files | Read first to understand old block system |

---

## Step 1 — Audit Old Builder Blocks

Read:

```
lib/mangocms_web/live/tenant/admin/page_live/builder.ex
lib/mangocms_web/live/tenant/admin/section_live/builder.ex
```

List every block type the old builder knows about so nothing is silently dropped.

---

## Step 2 — Replace Old Blocks with Manifest Components

- The builder palette (left-side drag panel) must list components from `MangoCMSWeb.Builder.Registry.all()` grouped by `manifest.group`
- Dragging a palette item creates a node via `Registry.default_node(name, variant_id)` and inserts it into the content tree
- The canvas renders nodes via `Renderer.node/1`
- Remove all code referencing old block types

---

## Step 3 — Create Missing Components

Check `lib/mangocms_web/builder/registry.ex` for what already exists before creating anything. For each new component:

- **(a)** Create `lib/mangocms_web/builder/manifests/<name>.ex`
- **(b)** Add renderer to the appropriate builder_library file, or create a new one (e.g. `typography_components.ex`, `media_components.ex`, `content_components.ex`, `utility_components.ex`)
- **(c)** Register in `lib/mangocms_web/builder/registry.ex`
- **(d)** Must appear in the UI Library at `/admin/ui-library`
- **(e)** Must add Alpine.js behaviour for any interactive state — follow the patterns in the Alpine.js Context section above

---

### Group: Typography

| Name | Description |
|---|---|
| `heading` | `<h1>`–`<h6>` — props: `text`, `level` (1–6), `size`, `weight`, `align`, `color` |
| `paragraph` | `<p>` block — props: `body`, `size`, `align`, `max_width`, `color` |
| `rich_text` | Rendered HTML/markdown body — props: `content` (textarea), `max_width` |
| `blockquote` | `<blockquote>` with styled left border — props: `text`, `author`, `cite` |
| `code_block` | Syntax-highlighted `<pre><code>` — props: `language`, `code` (textarea) |
| `ordered_list` | `<ol>` — props: `items` (action_list), `style` (decimal/alpha/roman) |
| `unordered_list` | `<ul>` — props: `items` (action_list), `style` (disc/circle/square) |
| `text_gradient` | Inline text with CSS gradient fill — props: `text`, `from_color`, `to_color`, `direction`, `size`, `weight` |
| `label_text` | Small uppercase eyebrow/label `<span>` — props: `text`, `color`, `size` |

---

### Group: Media

| Name | Description |
|---|---|
| `image` | `<img>` with `src` (media picker), `alt`, `aspect_ratio`, `object_fit`, `rounded`, `caption`; default src: `/images/no-image-placeholder.webp` |
| `video` | `<video>` or YouTube/Vimeo embed — props: `src`, `embed_type` (file/youtube/vimeo), `autoplay`, `controls`, `loop`, `aspect_ratio` |
| `audio` | `<audio>` player — props: `src`, `controls`, `autoplay`, `loop` |
| `gallery` | Responsive image grid — props: `images` (action_list of src+alt), `columns` (2–4), `gap`, `rounded`; clicking opens lightbox (Alpine: `owns: ["open", "active_index"]`) |
| `embed` | `<iframe>` wrapper — props: `url` (safe-checked), `aspect_ratio`, `title` |
| `icon_block` | Display icon with optional label — props: `icon` (icon field), `size`, `color`, `label`, `label_size`, `align` |

---

### Group: Layout

| Name | Description |
|---|---|
| `section` | Full-width `<section>` wrapper — props: `padding_y`, `padding_x`, `bg_color`, `bg_image` (media), `max_width`, `id` (anchor); slot: content |
| `container` | Max-width centering `<div>` — props: `max_width`, `padding_x`, `padding_y`, `bg_color`, `rounded`; `accepted_children: [*]` |
| `row` | Flex/grid row — props: `columns` (1–4), `gap`, `align`, `justify`, `wrap`; `accepted_children: [column, *]` |
| `column` | Flex column child — props: `span` (1–12), `padding`, `align`; `accepted_children: [*]` |
| `grid` | CSS grid with `template_columns` prop, `gap`, `align`; `accepted_children: [*]` |
| `spacer` | Empty vertical gap — props: `size` (xs/sm/md/lg/xl/2xl) |
| `divider` | Already exists — verify it is registered |

---

### Group: Content (Marketing / Editorial)

| Name | Description |
|---|---|
| `feature_card` | Icon + heading + body — props: `icon`, `title`, `body`, `icon_color`, `align`; variants: `with_border`, `colored_icon` |
| `feature_grid` | 2–4 column grid of feature items — props: `columns`, `items` (action_list of icon+title+body) |
| `cta_section` | Call-to-action block — props: `eyebrow`, `heading`, `body`, `primary_label`, `primary_href`, `secondary_label`, `secondary_href`, `align`; variants: `centered`, `left_aligned`, `with_image` |
| `testimonial` | Quote + author + avatar — props: `quote`, `author_name`, `author_role`, `avatar_src`, `rating` (0–5); variants: `card`, `minimal`, `large` |
| `testimonial_grid` | Grid of testimonial items — props: `columns`, `items` (action_list) |
| `pricing_card` | Single pricing tier — props: `name`, `price`, `period`, `currency`, `features` (action_list), `cta_label`, `cta_href`, `highlighted` (toggle), `badge_label` |
| `pricing_table` | Side-by-side pricing cards — props: `tiers` (action_list) |
| `team_member` | Photo + name + role + bio — props: `name`, `role`, `bio`, `avatar_src`, `social_links` (action_list of platform+href) |
| `team_grid` | Grid of team members — props: `columns`, `members` (action_list) |
| `faq_section` | FAQ list as accordion — props: `items` (action_list of question+answer), `style` (arrow/plus), `layout` (single/two_column); Alpine: `owns: ["open"]` (same pattern as `accordion`) |
| `banner` | Full-width announcement strip — props: `text`, `bg_color`, `text_color`, `dismissible` (toggle), `cta_label`, `cta_href`; Alpine: `owns: ["dismissed"]` |
| `logo_grid` | Partner/client logos — props: `logos` (action_list of src+alt+href), `columns` (3–8), `grayscale` (toggle) |
| `steps_section` | Numbered how-it-works steps — props: `items` (action_list of number+title+body), `layout` (horizontal/vertical), `icon_color` |
| `empty_state` | Zero-data placeholder — props: `icon`, `heading`, `body`, `cta_label`, `cta_href`; variants: `simple`, `with_image` |
| `notification_bar` | Sticky top-of-page notice — props: `text`, `type` (info/warn/error), `dismissible`, `cta_label`, `cta_href`, `bg_color`; Alpine: `owns: ["dismissed"]` |

---

### Group: Interactive / Utility

| Name | Description |
|---|---|
| `copy_button` | Copies value to clipboard — props: `label`, `value`, `copied_label`, `style`; Alpine: `owns: ["copied"]`, uses `navigator.clipboard`, auto-resets after 2 s |
| `read_more` | Truncated text with expand toggle — props: `body`, `lines` (2/3/4/5), `more_label`, `less_label`; Alpine: `owns: ["expanded"]`, uses `line-clamp-{n}` |
| `scroll_to_top` | Floating button shown on scroll — props: `position`, `style`, `threshold_px`; Alpine: `owns: ["visible"]`, `x-init` attaches `window` scroll listener |
| `cookie_banner` | GDPR consent bar — props: `text`, `accept_label`, `decline_label`, `privacy_href`; Alpine: `owns: ["dismissed"]`, persists accepted state to `localStorage` |
| `back_link` | ← Back navigation link — props: `label`, `href` |
| `share_buttons` | Social share row — props: `platforms` (action_list), `url`, `title`; each button opens share URL in new window |
| `table_of_contents` | Auto-generated anchor list — props: `heading_selector`, `title`; Alpine: `x-init` scans closest scrollable parent for matching headings |

---

## Step 4 — Inspector Fields

Every component must have a complete `fields` map in its manifest so the right-side inspector can edit every prop.

**Field DSL reference:**

```elixir
Field.text/2          # single-line text
Field.textarea/2      # multi-line text
Field.select/2        # dropdown — options: [{"Label", "value"}, ...]
Field.toggle/2        # boolean checkbox
Field.number/2        # numeric input
Field.color/2         # colour picker
Field.icon/2          # hero-icon picker
Field.media/2         # media library picker (image_src)
Field.link/2          # href + target
Field.action_list/2   # list of sub-items (repeater)
Field.class_list/2    # custom Tailwind classes
Field.slot_controls/2 # slot visibility toggles
```

---

## Step 5 — Tests

Add tests for all new components to:

```
test/mangocms_web/builder/registry_test.exs
```

Pattern for each batch:

```elixir
test "renders <group> component defaults" do
  assert render_component(&Renderer.node/1, node: Registry.default_node("heading")) =~ "h1"
  assert render_component(&Renderer.node/1, node: Registry.default_node("paragraph")) =~ "p"
  # ...
end

test "<group> manifests are in correct group with variants" do
  heading = Registry.get("heading")
  assert heading.group == "Typography"
  assert length(heading.variants) >= 1
end
```

Run after all changes:

```bash
MANGO_DB=sqlite3 mix precommit
```

All tests must pass with 0 failures.

---

## Conventions to Follow Strictly

### HTML Structure

- Primitive layout components (`section`, `container`, `row`, `column`, `grid`) must use `accepted_children: [...]` to declare what can nest inside them
- Components with slots must declare them in `slots:` and expose a `:slot_controls` field in the inspector

### Image Placeholder

Default image `src` must always be:

```
/images/no-image-placeholder.webp
```

Never hardcode any other URL.

### `href` Safety

All rendered `href` attributes must go through `safe_href/1`:

```elixir
@safe_schemes ["#", "/", "http://", "https://", "mailto:", "tel:"]

defp safe_href(href) when is_binary(href) do
  if Enum.any?(@safe_schemes, &String.starts_with?(href, &1)), do: href, else: "#"
end
defp safe_href(_), do: "#"
```

Defined in `action_components.ex` and `display_components.ex` — copy the pattern.

### Alpine.js

- `x-data` **always** uses `Jason.encode!` — never string interpolation `'#{value}'`
- Any container LiveView can patch needs: `id="stable-id" phx-hook="AlpineInit"`
- Alpine owns local UI state; LiveView owns persisted/shared state
- Declare `alpine: %{component: "<name>", owns: ["state_key"]}` in every manifest that uses Alpine
- See the Alpine.js Context section at the top of this document for all patterns

### Card Grid Thumbnails

- Component grid cards **must** use `<div phx-click={JS.patch(...)}>`
- **Never** use `<.link>` — it renders as `<a>`, and nested anchors break browsers

### Prop Naming Consistency

| Concept | Key name |
|---|---|
| Display/button text | `label` |
| Heading / semantic title | `title` |
| Body / paragraph text | `body` |
| Image URL | `image_src` / `avatar_src` / `src` |
| Link URL | `href` |
| Boolean toggles | `true` / `false` (not strings) |
| Variant id | `lowercase_snake_case` (e.g. `with_border`, `left_aligned`) |
