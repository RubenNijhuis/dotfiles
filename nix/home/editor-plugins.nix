{ pkgs, lib }:
let
  # One package set owns plugin revisions and native dependencies: flake.lock.
  names = [
    "CopilotChat.nvim"
    "LazyVim"
    "SchemaStore.nvim"
    "blink-copilot"
    "blink.cmp"
    "bufferline.nvim"
    "catppuccin"
    "conform.nvim"
    "copilot.lua"
    "crates.nvim"
    "diffview.nvim"
    "flash.nvim"
    "friendly-snippets"
    "fzf-lua"
    "gitsigns.nvim"
    "grug-far.nvim"
    "lazy.nvim"
    "lazydev.nvim"
    "lualine.nvim"
    "mason.nvim"
    "mini.ai"
    "mini.hipatterns"
    "mini.icons"
    "mini.pairs"
    "neo-tree.nvim"
    "noice.nvim"
    "nui.nvim"
    "nvim-lint"
    "nvim-lspconfig"
    "nvim-treesitter"
    "nvim-treesitter-textobjects"
    "nvim-ts-autotag"
    "persistence.nvim"
    "plenary.nvim"
    "rustaceanvim"
    "snacks.nvim"
    "todo-comments.nvim"
    "tokyonight.nvim"
    "trouble.nvim"
    "ts-comments.nvim"
    "venv-selector.nvim"
    "vim-tmux-navigator"
    "which-key.nvim"
  ];
  treesitter = pkgs.vimPlugins.nvim-treesitter.withPlugins (
    p: with p; [
      bash
      c
      c_sharp
      css
      diff
      html
      javascript
      jsdoc
      json
      json5
      lua
      luadoc
      luap
      markdown
      markdown_inline
      printf
      python
      query
      regex
      ruby
      rust
      scss
      svelte
      toml
      tsx
      typescript
      vim
      vimdoc
      xml
      yaml
    ]
  );
  # Treesitter's main branch discovers parsers under install_dir. Bundle only
  # the declared languages and their queries, rather than every grammar.
  parserBundle = pkgs.symlinkJoin {
    name = "nvim-parsers";
    paths = lib.unique (lib.concatMap (p: [ p ] ++ (p.dependencies or [ ])) treesitter.dependencies);
  };
  plugins = lib.genAttrs names (
    name:
    pkgs.vimPlugins.${
      if name == "catppuccin" then "catppuccin-nvim" else lib.replaceStrings [ "." ] [ "-" ] name
    }
  );
in
pkgs.writeText "nvim-plugin-registry.json" (
  builtins.toJSON {
    plugins = lib.mapAttrs (_: plugin: toString plugin) plugins;
    parsers = toString parserBundle;
    blinkVersion = pkgs.vimPlugins.blink-cmp.version;
  }
)
