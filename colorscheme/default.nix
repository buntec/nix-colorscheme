inputs:
{
  lib,
  pkgs,
  config,
  ...
}:
with lib;
let
  capitalizeFirst =
    s: lib.toUpper (builtins.substring 0 1 s) + builtins.substring 1 (lib.stringLength s) s;

  mkTokyoNight = style: {
    kitty-theme = "Tokyo Night ${capitalizeFirst style}";

    fish-init = builtins.readFile "${inputs.tokyonight}/extras/fish/tokyonight_${style}.fish";

    fish-theme-src = "${inputs.tokyonight}/extras/fish_themes";

    nvim-plugins = [ pkgs.vimPlugins.tokyonight-nvim ];

    # we put the plugin config here to ensure `colorscheme(...)` is called _after_ the config
    nvim-extra-conf = ''
      local tokyonight_style = "${style}"
      ${builtins.readFile ./nvim/tokyonight.lua}
      vim.cmd.colorscheme("tokyonight")
    '';

    tmux-extra-conf = builtins.readFile "${inputs.tokyonight}/extras/tmux/tokyonight_${style}.tmux";
  };

  tokyonight-themes = builtins.listToAttrs (
    map
      (style: {
        name = "tokyonight-${style}";
        value = mkTokyoNight style;
      })
      [
        "storm"
        "moon"
        "day"
        "night"
      ]
  );

  mkCatppuccin = flavor: {
    kitty-theme = "Catppuccin-${capitalizeFirst flavor}";

    fish-init = ''
      echo "y" | fish_config theme save "Catppuccin ${capitalizeFirst flavor}";
    '';

    fish-theme-src = "${inputs.catppuccin-fish}/themes";

    fish-plugins = [
      {
        name = "catppuccin";
        src = pkgs.fetchFromGitHub {
          owner = "catppuccin";
          repo = "fish";
          rev = "0ce27b518e8ead555dec34dd8be3df5bd75cff8e";
          sha256 = "sha256-Dc/zdxfzAUM5NX8PxzfljRbYvO9f9syuLO8yBr+R3qg=";
        };
      }
    ];

    nvim-plugins = [ pkgs.vimPlugins.catppuccin-nvim ];

    # we put the plugin config here to ensure `colorscheme(...)` is called _after_ the config
    nvim-extra-conf = ''
      local catppuccin_flavor = "${flavor}"
      ${builtins.readFile ./nvim/catppuccin.lua}
      vim.cmd.colorscheme("catppuccin")
    '';

    tmux-plugins = [ pkgs.tmuxPlugins.catppuccin ];

    tmux-extra-conf = ''
      set -g @catppuccin_flavour '${flavor}';
    '';

    emacs-extra-conf = ''
      (load-theme 'catppuccin :no-confirm)
      (setq catppuccin-flavor '${flavor})
      (catppuccin-reload)
    '';

    emacs-extra-packages = epkgs: [ epkgs.catppuccin-theme ];
  };

  catppuccin-themes = builtins.listToAttrs (
    map
      (flavor: {
        name = "catppuccin-${flavor}";
        value = mkCatppuccin flavor;
      })
      [
        "frappe"
        "mocha"
        "macchiato"
        "latte"
      ]
  );

  nightfox = {
    # nightfox is built into kitty, but we prefer the upstream version
    # kitty-theme = "Nightfox";

    kitty-extra-conf = builtins.readFile "${inputs.nightfox}/extra/nightfox/nightfox_kitty.conf";

    fish-init = builtins.readFile "${inputs.nightfox}/extra/nightfox/nightfox_fish.fish";

    nvim-plugins = [ pkgs.vimPlugins.nightfox-nvim ];

    # we put the plugin config here to ensure `colorscheme(...)` is called _after_ the config
    nvim-extra-conf = ''
      require('nightfox').setup({
        options = {
          styles = {
            comments = "italic",
            keywords = "italic",
          }
        }
      })
      vim.cmd.colorscheme("nightfox")
    '';

    tmux-extra-conf = builtins.readFile "${inputs.nightfox}/extra/nightfox/nightfox_tmux.tmux";
  };

  kanagawa = {
    kitty-extra-conf = builtins.readFile "${inputs.kanagawa}/extras/kanagawa.conf";

    fish-init = builtins.readFile "${inputs.kanagawa}/extras/kanagawa.fish";

    nvim-plugins = [ pkgs.vimPlugins.kanagawa-nvim ];

    # we put the plugin config here to ensure `colorscheme(...)` is called _after_ the config
    nvim-extra-conf = ''
      ${builtins.readFile ./nvim/kanagawa.lua}
      vim.cmd.colorscheme("kanagawa")
    '';

    emacs-extra-packages = epkgs: [
      epkgs.autothemer
      epkgs.kanagawa-theme
    ];

    emacs-extra-conf = ''
      (load-theme 'kanagawa)
    '';
  };

  doom-one = {
    kitty-extra-conf = builtins.readFile "${inputs.doom-one}/extras/kitty-dark.conf";

    nvim-plugins = [ pkgs.vimPlugins.doom-one-nvim ];

    # we put the plugin config here to ensure `colorscheme(...)` is called _after_ the config
    nvim-extra-conf = ''
      ${builtins.readFile ./nvim/doom-one.lua}
      vim.cmd.colorscheme("doom-one")
    '';

    # TODO emacs

    vscode-extensions = [ pkgs.vscode-marketplace.jaredkent.doom-vscode ];

    vscode-user-settings = ''
      "workbench.colorTheme" = "Doom One";
    '';
  };

  kauz = {
    kitty-extra-conf = ''
      include ${inputs.kauz.packages.${pkgs.system}.kauz-kitty}/kauz.conf
    '';
    nvim-plugins = [ inputs.kauz.packages.${pkgs.system}.kauz-nvim ];
    nvim-extra-conf = ''
      vim.cmd.colorscheme("kauz")
    '';
    fish-plugins = [
      {
        name = "kauz-fish";
        inherit (inputs.kauz.packages.${pkgs.system}.kauz-fish) src;
      }
    ];
    tmux-extra-conf = builtins.readFile "${inputs.kauz.packages.${pkgs.system}.kauz-tmux}/kauz.tmux";
  };

  themes = {
    inherit
      nightfox
      kanagawa
      doom-one
      kauz
      ;
  } // tokyonight-themes // catppuccin-themes;

  cfg = config.colorscheme;

  theme = themes.${cfg.name};
in
{

  options.colorscheme = {
    enable = mkEnableOption "a global colorscheme for kitty, fish, tmux and nvim";
    name = mkOption {
      type = types.enum (builtins.attrNames themes);
      default = "tokyonight-storm";
    };
  };

  config = mkIf cfg.enable {

    programs.kitty.themeFile = mkIf (hasAttr "kitty-theme" theme) theme.kitty-theme;

    programs.kitty.extraConfig = theme.kitty-extra-conf or "";

    programs.tmux.extraConfig = theme.tmux-extra-conf or "";

    programs.tmux.plugins = theme.tmux-plugins or [ ];

    programs.fish.interactiveShellInit = theme.fish-init or "";

    programs.fish.plugins = theme.fish-plugins or [ ];

    programs.neovim.plugins = theme.nvim-plugins or [ ];

    programs.neovim.extraLuaConfig = theme.nvim-extra-conf or "";

    xdg.configFile = mkIf (hasAttr "fish-theme-src" theme) {
      "fish/themes".source = theme.fish-theme-src;
    };

    programs.emacs.extraConfig = theme.emacs-extra-conf or "";

    programs.emacs.extraPackages = theme.emacs-extra-packages or (epkgs: [ ]);
  };
}
