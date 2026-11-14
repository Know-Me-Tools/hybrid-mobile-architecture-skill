# od-prototype.json → mini-app manifest

`od-prototype.json` is written by KnowDesign's `htmx-alpine-prototype` template next to a working prototype page. Each field maps to exactly one part of the mini-app manifest or its implementation.

| od-prototype.json | Mini-app module |
|---|---|
| `title` | Module display name; derive the stable module ID from it (kebab-case) |
| `entities[].name` | Entity type name (singular PascalCase for code, plural for collections) |
| `entities[].fields` (`string`, `text`, `url`, `email`, `number`, `boolean`, `date`, `datetime`) | Entity field types: Dart `String` / `num` / `bool` / `DateTime`; TypeScript `string` / `number` / `boolean` / ISO string |
| `routes[]` with `kind: list` / `detail` | Repository read methods (`list()`, `get(id)`) and the screens that show them |
| `routes[]` with `kind: create` / `update` / `delete` / `toggle` | Repository write methods; each needs a policy action (server mutations require verified identity and policy enforcement) |
| `routes[]` with `kind: form` | UI only: an edit mode of the screen, no repository method |
| `routes[].responses[].status: 422` + `when` | Domain validation errors returned by the write method |
| `routes[].responses[].triggers` | Event contracts the module emits after the write succeeds |
| `components[]` (`name`, `entity`, `repeats`) | Screens and widgets; `repeats: true` is a list item widget |
| `components[].routes` | Which repository methods each screen's view model calls |
| `state[]` (Alpine `x-data`) | Local widget state; not part of the manifest |
| `tokens.roles` | Role names already used by `hybrid-design-tokens`; copy values from `tokens.source` into `tokens.toml` |

Not in the prototype, so add by hand: capabilities (deny-by-default), policy actions per write, migrations, agent triggers (via the governed UAR gateway), and offline/sync behaviour.

Validation: the manifest is only a seed. The module is done when the tests in `SKILL.md`'s Done section pass.
