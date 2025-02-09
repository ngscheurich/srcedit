-- [nfnl] Compiled from fnl/srcedit/init.fnl by https://github.com/Olical/nfnl, do not edit.
local _local_1_ = require("srcedit.nfnl.module")
local autoload = _local_1_["autoload"]
local _local_2_ = autoload("srcedit.nfnl.core")
local get = _local_2_["get"]
local get_in = _local_2_["get-in"]
local map = _local_2_["map"]
local nil_3f = _local_2_["nil?"]
local pr = _local_2_["pr"]
local pr_sit = _local_2_["pr-sit"]
local reduce = _local_2_["reduce"]
local ts_utils = autoload("nvim-treesitter.ts_utils")
local config = {keys = {edit = "<Leader><Leader>", apply = "<Leader><Leader>"}}
local function get_parser()
  local parser, err = vim.treesitter.get_parser(0, "markdown")
  if err then
    return error(err)
  else
    return parser
  end
end
local function get_root(parser)
  local tree = parser:parse()
  if tree then
    return tree[1]:root()
  else
    return error("could-not-get-tree")
  end
end
local function current_node()
  local parser = get_parser()
  local root = get_root(parser)
  local r, col = unpack(vim.api.nvim_win_get_cursor(0))
  local row = (r - 1)
  return root:named_descendant_for_range(row, col, row, col)
end
local function parent_code_block(node)
  if nil_3f(node) then
    return nil
  else
    local _5_ = node:type()
    if (_5_ == "fenced_code_block") then
      return node
    else
      local _ = _5_
      return parent_code_block(node:parent())
    end
  end
end
local function apply_edits(buf, src_buf, start, _end)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, true)
  vim.api.nvim_buf_set_lines(src_buf, start, _end, true, lines)
  return vim.api.nvim_buf_delete(buf, {force = true})
end
local function child_of_type(node, type)
  local ns = ts_utils.get_named_children(node)
  local t = {}
  for _, v in ipairs(ns) do
    t[v:type()] = v
  end
  return get(t, type)
end
local function edit(node)
  local src_buf = vim.api.nvim_buf_get_number(0)
  local new_buf = vim.api.nvim_create_buf(false, true)
  local info = child_of_type(node, "info_string")
  local lang = child_of_type(info, "language")
  local lang_text = vim.treesitter.get_node_text(lang, src_buf)
  local code = child_of_type(node, "code_fence_content")
  local code_text = vim.treesitter.get_node_text(code, src_buf)
  local code_start, _, code_end, _0 = code:range()
  local apply_fn
  local function _8_()
    return apply_edits(new_buf, src_buf, code_start, code_end)
  end
  apply_fn = _8_
  local lines = vim.split(code_text, "\n", {plain = true})
  local key_apply = get_in(_G, {"srcedit", "key-apply"})
  local cmd_apply_3f = get_in(_G, {"srcedit", "cmd-apply?"}, false)
  vim.api.nvim_buf_set_lines(new_buf, 0, -1, true, lines)
  vim.api.nvim_buf_set_option(new_buf, "filetype", lang_text)
  vim.cmd("split")
  vim.cmd(("buffer " .. new_buf))
  if key_apply then
    vim.keymap.set("n", key_apply, apply_fn, {buffer = true})
  else
  end
  if cmd_apply_3f then
    return vim.api.nvim_create_user_command("SrceditApply", apply_fn, {})
  else
    return nil
  end
end
local function get_opt(user_config, ks)
  return get_in(user_config, ks, get_in(config, ks))
end
local function setup(tbl)
  _G["srcedit"] = {}
  local user_config = (tbl or {})
  local key_edit = get_opt(user_config, {"keys", "edit"})
  local key_apply = get_opt(user_config, {"keys", "apply"})
  local function _11_()
    local node = current_node()
    local code_block = parent_code_block(node)
    if code_block then
      return edit(code_block)
    else
      return nil
    end
  end
  vim.keymap.set("n", key_edit, _11_)
  _G.srcedit["key-apply"] = key_apply
  return nil
end
setup()
return {setup = setup}
