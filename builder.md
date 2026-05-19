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
