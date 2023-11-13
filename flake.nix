{
  description = "A home-manager module for managing color schemes";

  inputs = {

    tokyonight = {
      url = "github:folke/tokyonight.nvim";
      flake = false;
    };

    nightfox = {
      url = "github:EdenEast/nightfox.nvim";
      flake = false;
    };

    catppuccin-fish = {
      url = "github:catppuccin/fish";
      flake = false;
    };

  };

  outputs = inputs@{ self, ... }: {

    homeModules = { colorscheme = import ./colorscheme inputs; };

  };

}
