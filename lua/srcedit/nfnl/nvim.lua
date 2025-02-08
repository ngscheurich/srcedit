-- [nfnl] Compiled from fnl/nfnl/nvim.fnl by https://github.com/Olical/nfnl, do not edit.
local _local_1_ = require("srcedit.nfnl.module")
local autoload = _local_1_["autoload"]
local str = autoload("srcedit.nfnl.string")
local function get_buf_content_as_string(buf)
  return (str.join("\n", vim.api.nvim_buf_get_lines((buf or 0), 0, -1, false)) or "")
end
return {["get-buf-content-as-string"] = get_buf_content_as_string}
