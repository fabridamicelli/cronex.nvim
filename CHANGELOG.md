## 0.3.0 (2025-05-08)
## Feat
- Add support for `crontab` format by @kylesnowschwartz #8 : Implement `cron_from_line_crontab` to parse format `cron cmd`.

See [this example config](https://github.com/fabridamicelli/cronex.nvim/blob/main/examples/crontab_config.lua)

## 0.2.1 (2025-05-03)
Improve test coverage and documentation.

## 0.2.0 (2025-04-29)

### Breaking changes
- Require: `Neovim` version >=0.10 
- The namespace used by the plugin is now called "plugin-cronex.nvim" (previously "cronex"). That should be updated in case you are relying on it, eg `vim.api.nvim_get_namespaces()["cronex"]` --> `vim.api.nvim_get_namespaces()["cronex"]`

### Feat
- Non-blocking system call in explainer: System calls occur asynchronously in the background and the diagnostics are populated as they come from stdout. This allows for the user to keep editing text without interruption even with a lot of cron expressions on the buffer.
- Explainer now accepts parameter `timeout` (default 10000 milliseconds) to limit the waiting time.

### Refactor
These are changes in the internar implementations which do not affect the User API.

- Replace deprecated `vim.tbl_flatten` with `vim.iter():flatten():totable()`
- Remove `config.format` (passed directly to explain)
- Remove unnecessary `M.hide_explanations`
- Remove unnecessary `autocmd` on `api.nvim_create_autocmd({ "InsertEnter" }`

