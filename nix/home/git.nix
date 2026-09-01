{ ... }:

{
  # This writes XDG Git configuration. `make nix-adopt PROFILE=git` performs
  # the explicit, backed-up handoff for any pre-Nix Git files.
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Ruben Nijhuis";
        email = "contact@rubennijhuis.com";
      };

      core = {
        excludesFile = "~/.config/git/ignore";
        pager = "delta";
      };

      interactive.diffFilter = "delta --color-only";

      delta = {
        navigate = true;
        side-by-side = true;
        line-numbers = true;
        syntax-theme = "ansi";
        minus-style = "syntax #37222c";
        minus-emph-style = "syntax #713137";
        plus-style = "syntax #20303b";
        plus-emph-style = "syntax #2c5a66";
        line-numbers-minus-style = "#f7768e";
        line-numbers-plus-style = "#9ece6a";
        line-numbers-zero-style = "#414868";
        hunk-header-decoration-style = "blue box";
      };

      gpg.program = "gpg";
      credential.helper = "osxkeychain";
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      fetch = {
        prune = true;
        pruneTags = true;
      };
      merge.conflictstyle = "zdiff3";
      rerere.enabled = true;
      help.autoCorrect = 20;

      alias = {
        lg = "log --graph --oneline --all --decorate";
        undo = "reset HEAD~1 --soft";
        amend = "commit --amend --no-edit";
        st = "status -sb";
        co = "checkout";
        br = "branch";
        ci = "commit";
        unstage = "reset HEAD --";
        last = "log -1 HEAD";
        push-force = "push --force-with-lease";
        stash-all = "stash push -u";
        wt = "worktree";
      };

      maintenance = {
        auto = true;
        strategy = "incremental";
      };
    };

    ignores = [
      ".DS_Store"
      ".idea"
      "*.swp"
      "*.swo"
      "*~"
      ".vscode/"
      ".env"
      ".env.local"
    ];

    includes = [
      {
        condition = "gitdir:**/personal/**";
        contents = {
          user.email = "contact@rubennijhuis.com";
          core.sshCommand = "ssh -i ~/.ssh/id_ed25519_personal -F ~/.ssh/config";
        };
      }
      {
        condition = "gitdir:**/archive/**";
        contents = {
          user.email = "contact@rubennijhuis.com";
          core.sshCommand = "ssh -i ~/.ssh/id_ed25519_personal -F ~/.ssh/config";
        };
      }
    ];
  };
}
