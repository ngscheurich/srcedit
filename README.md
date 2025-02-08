# srcedit

This is a Markdown file.

```lua
if node:type() == "sigil" then
  vim.print("cool")
end
```

```lua
local function set_buf_mapping(buf, src_buf, start, end_, indent)

  local cmd_str = "lua require('edeex').apply(%s, %s, %s, %s, '%s')"
  local cmd = string.format(cmd_str, buf, src_buf, start + 1, end_, indent)

  vim.api.nvim_buf_set_keymap(buf, "n", lhs, "<Cmd>" .. cmd .. "<CR>", {noremap = true})
  vim.api.nvim_buf_set_keymap(buf, "i", lhs, "<Cmd>" .. cmd .. "<CR>", {noremap = true})
end
```

