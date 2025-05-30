{
  inputs = {
    hyprutils = {
      url = "github:hyprwm/hyprutils";
      inputs.nixpkgs.follows = "hyprland/nixpkgs";
    };
    hyprland = {
      url = "git+https://github.com/hyprwm/Hyprland?rev=55e953b383f6b658b20ede1fea7772d2a88e7c65";
      inputs.hyprutils.follows = "hyprutils";
    };
  };

  outputs = {hyprland, ...}: let
    inherit (hyprland.inputs) nixpkgs;

    hyprlandSystems = fn:
      nixpkgs.lib.genAttrs
      (builtins.attrNames hyprland.packages)
      (system: fn system nixpkgs.legacyPackages.${system});

    hyprlandVersion = nixpkgs.lib.removeSuffix "\n" (builtins.readFile "${hyprland}/VERSION");
  in {
    packages = hyprlandSystems (system: pkgs: rec {
      hy3 = pkgs.callPackage ./default.nix {
        hyprland = hyprland.packages.${system}.hyprland;
        hlversion = hyprlandVersion;
      };
      default = hy3;
    });

    devShells = hyprlandSystems (system: pkgs: {
      default = import ./shell.nix {
        inherit pkgs;
        hlversion = hyprlandVersion;
        hyprland = hyprland.packages.${system}.hyprland-debug;
      };

      impure = import ./shell.nix {
        pkgs = import <nixpkgs> {};
        hlversion = hyprlandVersion;
        hyprland = (pkgs.appendOverlays [hyprland.overlays.hyprland-packages]).hyprland-debug.overrideAttrs {
          dontStrip = true;
        };
      };
    });
  };
}
