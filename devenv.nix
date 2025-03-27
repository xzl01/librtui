{ pkgs, lib, config, ... }:

{
  # https://devenv.sh/packages/
  packages = with pkgs; [
    mdbook
    mdbook-admonish
    mdbook-i18n-helpers
    mdbook-linkcheck
    mdbook-toc
  ];

  pre-commit = {
    hooks = {
      commitizen.enable = true;
      shellcheck = {
        enable = true;
        entry = lib.mkForce "${pkgs.shellcheck}/bin/shellcheck -x";
      };
      shfmt.enable = true;
      statix.enable = true;
      typos = {
        enable = true;
        excludes = [
          "theme/highlight.js"
        ];
      };
    };
  };

  starship.enable = true;
}
