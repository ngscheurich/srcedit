;;; Srcedit
;;;
;;; Documentation

(local {: autoload} (require :srcedit.nfnl.module))
(local {: get-in : nil?} (autoload :srcedit.nfnl.core))

(local config {})

(fn get-parser []
  "Returns a tree of parsers (LanguageTree) for the current buffer using the
  Markdown grammar."
  (let [(parser err) (vim.treesitter.get_parser 0 :markdown)]
    (if err (error err) parser)))

(fn get-root [parser]
  "Returns a tree-sitter tree (TSTree) by running the parser."
  (let [tree (parser:parse)]
    (if tree
        (: (. tree 1) :root)
        (error :could-not-get-tree))))

(fn current-node []
  "Returns the named descendant TSNode at the cursor position."
  (let [parser (get-parser)
        root (get-root parser)
        (r col) (unpack (vim.api.nvim_win_get_cursor 0))
        row (- r 1)]
    (root:named_descendant_for_range row col row col)))

(fn parent-code-block [node]
  "Returns the parent `fenced_code_block` TSNode if one exists."
  (if (nil? node)
      nil
      (case (node:type)
        :fenced_code_block node
        _ (parent-code-block (node:parent)))))

(fn apply-edits [buf src-buf start end]
  "Updates the code block in the source buffer."
  (let [lines (vim.api.nvim_buf_get_lines buf 0 -1 true)]
    (vim.api.nvim_buf_set_lines src-buf start end true lines)
    (vim.api.nvim_buf_delete buf {:force true})))

(fn edit [node]
  (let [
        src-buf (vim.api.nvim_buf_get_number 0)
        new-buf (vim.api.nvim_create_buf false true)
        lang (node:child 1)
        lang-text (vim.treesitter.get_node_text lang src-buf)
        code (node:child 3)
        code-text (vim.treesitter.get_node_text code src-buf)
        (code-start _ code-end _) (code:range)
        apply-fn #(apply-edits new-buf src-buf code-start code-end)
        lines (vim.split code-text "\n" {:plain true})]

    (vim.api.nvim_buf_set_lines new-buf 0 -1 true lines)
    (vim.api.nvim_buf_set_option new-buf :filetype lang-text)
    (vim.cmd "split")
    (vim.cmd (.. "buffer " new-buf))
    (vim.api.nvim_create_user_command :SrceditApply apply-fn {})))

(fn setup [config]
  nil)

(let [config {:keymaps {}}
      user-config {:keymaps {:edit :<Leader>e}}]
  (get-in user-config [:keymaps :apply] (get-in config [:keymaps :apply])))

{: setup
 :apply_edits apply-edits}
