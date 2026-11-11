# Babel

Czech ⇄ Italian translator for the Omarchy bar, powered by the `claude` CLI.

- Click the bar icon to open two columns, Čeština and Italiano. Type into either one and press the arrow in the middle (or `Ctrl+Enter`) to translate into the other. `Tab` switches columns, `Esc` closes.
- Select text anywhere (or copy it) and press `SUPER + B`. The panel opens with the selection in its detected language and the translation beside it.

## Setup

```bash
omarchy plugin enable smetak13.babel
```

```lua
-- ~/.config/hypr/bindings.lua
o.bind("SUPER + B", "Babel: translate selection", "$HOME/.config/omarchy/plugins/smetak13.babel/bin/babel grab")
```

Requires `claude` (logged in), `wl-clipboard` and Node for the tests.

## Layout

- `Panel.qml` – bar icon and the two-column panel
- `Model.js` – language pair, prompts, reply schema and reply parsing
- `bin/babel` – `grab` reads the primary selection (falling back to the clipboard) and sends it to the open panel; `translate` runs `claude -p` with structured output

## Tests

```bash
node --test tests/
```
