Use **high intelligence for the foundation**, then **medium for batches**, then **high again for review/refactor**. Don’t ask for all components in one prompt. It will create a pile of code, but the patterns will drift.

**Best Order**

1. **High**: Foundation
2. **Medium/High**: First golden components
3. **Medium**: Action + Feedback
4. **Medium**: Layout + Navigation
5. **Medium**: Data display
6. **Medium**: Data input
7. **Low/Medium**: Mockups + simple display
8. **High**: UI Library page + final integration review

**Prompt 1: Foundation, Use High**

```text
Implement the MangoCMS builder component foundation.

Create Elixir-native component manifests, not JSON manifest files.

Requirements:
- Add a Builder.Registry that loads component manifests from Elixir modules.
- Add Builder.Field helpers for text, textarea, select, toggle, media, link, action_list, class_list, number, color, icon, slot controls.
- Add manifest contract supporting:
  - name, label, group, icon
  - renderer module/function
  - default_variant
  - variants
  - default_props
  - default_classes
  - fields
  - slots
  - accepted children
  - Alpine behavior metadata if needed
- Add generic inspector field renderer that can render right-sidebar fields from a manifest.
- Add slot support contract, but do not fully refactor all existing builder tree logic yet unless required.
- Add tests for registry lookup, default node creation, variant lookup, and field extraction.
- Keep Phoenix components separate from builder wrappers.
- Run mix precommit.
```

**Prompt 2: Golden Components, Use High**

Start with components that prove variants, slots, props, and Alpine behavior.

```text
Using the new manifest foundation, implement these first golden components:

1. Button
2. Card
3. Hero
4. Modal
5. Dropdown
6. Carousel
7. Tabs
8. Input

For each:
- Create Phoenix function component renderer.
- Add Elixir manifest with variants, fields, slots, default props, default classes.
- Add builder inspector support from manifest fields.
- Add public rendering support.
- Add Alpine behavior only where needed.
- Add examples for each variant.
- Ensure components can be rendered in builder and public mode.
- Add focused tests for manifest and rendering.
- Run mix precommit.
```

**Prompt 3: Action Components, Use Medium**

```text
Implement MangoCMS Action UI components using the manifest system:

- Button
- Dropdown
- FAB / Speed Dial
- Modal
- Swap
- Theme Controller

For each component:
- Add possible variants.
- Add slots where useful.
- Add manifest fields for right sidebar editing.
- Add Alpine behavior metadata and JS/Alpine behavior where needed.
- Add default props/classes.
- Add public renderer support.
- Add examples for UI Library preview.
- Add tests for manifest defaults and rendering.
- Run mix precommit.
```

**Prompt 4: Feedback Components, Use Medium**

```text
Implement MangoCMS Feedback UI components using the manifest system:

- Alert
- Loading
- Progress
- Radial Progress
- Skeleton
- Toast
- Tooltip

For each:
- Add variants, sizes, tones, and default props.
- Add manifest fields for inspector editing.
- Add Alpine behavior for toast/tooltip if needed.
- Add public renderer support.
- Add UI Library examples.
- Add tests.
- Run mix precommit.
```

**Prompt 5: Layout Components, Use Medium/High**

This matters because layout affects slots/drop rules.

```text
Implement MangoCMS Layout UI components using the manifest system:

- Divider
- Drawer sidebar
- Footer
- Hero
- Indicator
- Join
- Mask
- Stack

For each:
- Define slots and accepted child types.
- Add layout variants and responsive settings.
- Add manifest inspector fields.
- Add public renderer support.
- Ensure drawer and hero support Alpine behavior where needed.
- Add UI Library examples.
- Add tests.
- Run mix precommit.
```

**Prompt 6: Navigation Components, Use Medium**

```text
Implement MangoCMS Navigation UI components using the manifest system:

- Breadcrumbs
- Dock
- Link
- Menu
- Navbar
- Pagination
- Steps
- Tabs

For each:
- Add variants, slots, and accepted children.
- Add manifest fields for labels, links, active item, alignment, responsive options.
- Add Alpine behavior for menu/tabs/navbar where needed.
- Add public renderer support.
- Add UI Library examples.
- Add tests.
- Run mix precommit.
```

**Prompt 7: Data Display Part 1, Use Medium/High**

These are more complex and dynamic.

```text
Implement MangoCMS Data Display components, batch 1:

- Accordion
- Card
- Carousel
- Collapse
- List
- Stat
- Table
- Timeline

For each:
- Add variants and slots.
- Add collection-binding friendly fields.
- Add manifest right-sidebar fields.
- Add dynamic binding support using {{item.field}} values where relevant.
- Add Alpine behavior for accordion/collapse/carousel.
- Add public renderer support.
- Add UI Library examples.
- Add tests.
- Run mix precommit.
```

**Prompt 8: Data Display Part 2, Use Medium**

```text
Implement MangoCMS Data Display components, batch 2:

- Avatar
- Badge
- Chat bubble
- Countdown
- Diff
- Hover 3D card
- Hover Gallery
- Kbd
- Status
- Text Rotate

For each:
- Add variants and default props/classes.
- Add manifest inspector fields.
- Add Alpine behavior for countdown, diff, hover gallery, text rotate where needed.
- Add public renderer support.
- Add UI Library examples.
- Add tests.
- Run mix precommit.
```

**Prompt 9: Data Input Part 1, Use Medium/High**

```text
Implement MangoCMS Data Input components, batch 1:

- Input field
- Textarea
- Select
- Checkbox
- Radio
- Toggle
- Range
- Rating

For each:
- Add Phoenix function component renderer.
- Add manifest fields and validation metadata.
- Support form context and standalone builder preview context.
- Add variants, sizes, disabled/error states.
- Add UI Library examples.
- Add tests.
- Run mix precommit.
```

**Prompt 10: Data Input Part 2, Use Medium**

```text
Implement MangoCMS Data Input components, batch 2:

- Calendar
- Fieldset
- File Input
- Filter
- Label
- Validator

For each:
- Add variants and inspector fields.
- Add Alpine behavior where needed.
- Integrate file input with existing media/file manager pattern where appropriate.
- Add UI Library examples.
- Add tests.
- Run mix precommit.
```

**Prompt 11: Mockup Components, Use Low/Medium**

```text
Implement MangoCMS Mockup UI components using the manifest system:

- Browser mockup
- Code mockup
- Phone mockup
- Window mockup

For each:
- Add variants and default props/classes.
- Add slots where useful.
- Add manifest inspector fields.
- Add public renderer support.
- Add UI Library examples.
- Add tests.
- Run mix precommit.
```

**Prompt 12: UI Library Page, Use High**

```text
Create a MangoCMS UI Library page for all manifest components.

Requirements:
- Route under tenant admin or platform admin, whichever fits existing admin navigation.
- List all components from Builder.Registry.
- Filter by group, name, variant, and behavior.
- Show live preview for each component.
- Allow changing manifest-exposed properties in a right-side inspector.
- Show variants for selected component.
- Show slots visually where applicable.
- Show generated content-tree node preview.
- Include search.
- Include responsive preview controls.
- Keep this page separate from the page/section builder.
- Add tests for route access, registry rendering, filters, and basic property updates.
- Run mix precommit.
```

**Prompt 13: Final Review, Use High**

```text
Review the full MangoCMS UI component manifest system.

Check for:
- duplicated manifest field definitions
- inconsistent prop names
- inconsistent variant names
- missing slots
- missing inspector fields
- unsafe classes or URLs
- Alpine/LiveView boundary problems
- public renderer drift
- missing tests
- performance issues
- components that should be split or merged

Fix issues found and run mix precommit.
```

**Recommended Intelligence**

Use this mapping:

```text
High:
- Foundation
- Golden components
- Layout components
- Data display batch 1
- UI Library page
- Final review

Medium:
- Action
- Feedback
- Navigation
- Data display batch 2
- Data input

Low/Medium:
- Mockups
- Simple components like badge, kbd, divider, loading, skeleton
```

**Most Important Advice**

Do not ask:

```text
Create all daisyUI components with variants.
```

Ask in batches, and require each batch to:

- use the manifest system
- add UI Library examples
- add tests
- run precommit

That way the system stays coherent instead of becoming a beautiful mess with seventeen slightly different patterns.

Action
<a href="/components/button/">Button</a>
<a href="/components/dropdown/">Dropdown</a>
<a href="/components/fab/">FAB / Speed Dial</a>
<a href="/components/modal/">Modal</a>
<a href="/components/swap/">Swap</a>
<a href="/components/theme-controller/">Theme Controller</a>

Data display
<a href="/components/accordion/">Accordion</a>
<a href="/components/avatar/">Avatar</a>
<a href="/components/badge/">Badge</a>
<a href="/components/card/">Card</a>
<a href="/components/carousel/">Carousel</a>
<a href="/components/chat/">Chat bubble</a>
<a href="/components/collapse/">Collapse</a>
<a href="/components/countdown/">Countdownupdated</span></a>
<a href="/components/diff/">Diff</a>
<a href="/components/hover-3d/">Hover 3D card</a>
<a href="/components/hover-gallery/">Hover Gallery</a>
<a href="/components/kbd/">Kbd</a>
<a href="/components/list/">List</a>
<a href="/components/stat/">Stat</a>
<a href="/components/status/">Status</a>
<a href="/components/table/">Table</a>
<a href="/components/text-rotate/">Text Rotate</a>
<a href="/components/timeline/">Timeline</a>

Navigation
<a href="/components/breadcrumbs/">Breadcrumbs</a>
<a href="/components/dock/">Dock</a>
<a href="/components/link/">Link</a>
<a href="/components/menu/">Menu</a>
<a href="/components/navbar/">Navbar</a>
<a href="/components/pagination/">Pagination</a>
<a href="/components/steps/">Steps</a>
<a href="/components/tab/">Tab</a>

Feedback
<a href="/components/alert/">Alert</a>
<a href="/components/loading/">Loading</a>
<a href="/components/progress/">Progress</a>
<a href="/components/radial-progress/">Radial progress</a>
<a href="/components/skeleton/">Skeletonupdated</span></a>
<a href="/components/toast/">Toast</a>
<a href="/components/tooltip/">Tooltip</a>

Data input
<a href="/components/calendar/">Calendar</a>
<a href="/components/checkbox/">Checkbox</a>
<a href="/components/fieldset/">Fieldset</a>
<a href="/components/file-input/">File Input</a>
<a href="/components/filter/">Filter</a>
<a href="/components/label/">Label</a>
<a href="/components/radio/">Radio</a>
<a href="/components/range/">Range</a>
<a href="/components/rating/">Rating</a>
<a href="/components/select/">Selectupdated</span></a>
<a href="/components/input/">Input field</a>
<a href="/components/textarea/">Textarea</a>
<a href="/components/toggle/">Toggle</a>
<a href="/components/validator/">Validator</a>

Layout
<a href="/components/divider/">Divider</a>
<a href="/components/drawer/">Drawer sidebarupdated</span></a>
<a href="/components/footer/">Footer</a>
<a href="/components/hero/">Hero</a>
<a href="/components/indicator/">Indicator</a>
<a href="/components/join/">Join (group items)</a>
<a href="/components/mask/">Mask</a>
<a href="/components/stack/">Stack</a>

Mockup
<a href="/components/mockup-browser/">Browser</a>
<a href="/components/mockup-code/">Code</a>
<a href="/components/mockup-phone/">Phone</a>
<a href="/components/mockup-window/">Window</a>



Here's the prompt in MD format:

---

# Section Builder Migration + Complete Component Library

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
| `gallery` | Responsive image grid — props: `images` (action_list of src+alt), `columns` (2–4), `gap`, `rounded`; clicking opens lightbox (Alpine) |
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
| `faq_section` | FAQ list as accordion — props: `items` (action_list of question+answer), `style` (arrow/plus), `layout` (single/two_column) |
| `banner` | Full-width announcement strip — props: `text`, `bg_color`, `text_color`, `dismissible` (toggle, Alpine), `cta_label`, `cta_href` |
| `logo_grid` | Partner/client logos — props: `logos` (action_list of src+alt+href), `columns` (3–8), `grayscale` (toggle) |
| `steps_section` | Numbered how-it-works steps — props: `items` (action_list of number+title+body), `layout` (horizontal/vertical), `icon_color` |
| `empty_state` | Zero-data placeholder — props: `icon`, `heading`, `body`, `cta_label`, `cta_href`; variants: `simple`, `with_image` |
| `notification_bar` | Sticky top-of-page notice — props: `text`, `type` (info/warn/error), `dismissible`, `cta_label`, `cta_href`, `bg_color`; Alpine for dismiss |

---

### Group: Interactive / Utility

| Name | Description |
|---|---|
| `copy_button` | Copies value to clipboard — props: `label`, `value`, `copied_label`, `style`; Alpine: `owns: ["copied"]`, uses `navigator.clipboard` |
| `read_more` | Truncated text with expand toggle — props: `body`, `lines` (2/3/4/5), `more_label`, `less_label`; Alpine: `owns: ["expanded"]` |
| `scroll_to_top` | Floating button shown on scroll — props: `position`, `style`, `threshold_px`; Alpine: `owns: ["visible"]`, uses `window` scroll listener |
| `cookie_banner` | GDPR consent bar — props: `text`, `accept_label`, `decline_label`, `privacy_href`; Alpine: `owns: ["dismissed"]`, persists to `localStorage` |
| `back_link` | ← Back navigation link — props: `label`, `href` |
| `share_buttons` | Social share row — props: `platforms` (action_list), `url`, `title`; each button opens share URL in new window |
| `table_of_contents` | Auto-generated anchor list — props: `heading_selector`, `title`; Alpine: scans parent DOM for headings on `x-init` |

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