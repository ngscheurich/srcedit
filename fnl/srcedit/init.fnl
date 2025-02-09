;;; Srcedit
;;;
;;; Documentation

(local {: autoload} (require :srcedit.nfnl.module))
(local {: get : get-in : map : nil? : pr : pr-sit : reduce} (autoload :srcedit.nfnl.core))
(local ts-utils (autoload :nvim-treesitter.ts_utils))

(local config {:keys {:edit :<Leader><Leader>
                      :apply :<Leader><Leader>}})

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

(fn child-of-type [node type]
  (let [ns (ts-utils.get_named_children node)
        t {}]
    (each [_ v (ipairs ns)] (tset t (v:type) v))
    (get t type)))

(fn edit [node]
  (let [src-buf (vim.api.nvim_buf_get_number 0)
        new-buf (vim.api.nvim_create_buf false true)
        info (child-of-type node :info_string)
        lang (child-of-type info :language)
        lang-text (vim.treesitter.get_node_text lang src-buf)
        code (child-of-type node :code_fence_content)
        code-text (vim.treesitter.get_node_text code src-buf)
        (code-start _ code-end _) (code:range)
        apply-fn #(apply-edits new-buf src-buf code-start code-end)
        lines (vim.split code-text "\n" {:plain true})
        key-apply (get-in _G [:srcedit :key-apply])
        cmd-apply? (get-in _G [:srcedit :cmd-apply?] false)]

    (vim.api.nvim_buf_set_lines new-buf 0 -1 true lines)
    (vim.api.nvim_buf_set_option new-buf :filetype lang-text)
    (vim.cmd :split)
    (vim.cmd (.. "buffer " new-buf))

    (when key-apply
      (vim.keymap.set :n key-apply apply-fn {:buffer true}))
    
    (when cmd-apply?
      (vim.api.nvim_create_user_command :SrceditApply apply-fn {}))))

(fn get-opt [user-config ks]
  (get-in user-config ks (get-in config ks)))

(fn setup [tbl]
  (tset _G :srcedit {})

  (let [user-config (or tbl {})
        key-edit (get-opt user-config [:keys :edit])
        key-apply (get-opt user-config [:keys :apply])]

    (vim.keymap.set :n key-edit (fn []
                                  (let [node (current-node)
                                             code-block (parent-code-block node)]
                                    (when code-block (edit code-block)))))

    (tset _G.srcedit :key-apply key-apply)))

(setup)

{: setup}
