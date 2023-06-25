{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";

  inputs.fenix.url = "github:nix-community/fenix";
  inputs.fenix.inputs.nixpkgs.follows = "nixpkgs";

  outputs = { self, nixpkgs, fenix }: let

    modules = [
      ./odin.nix
      ./wivrn.nix
      ./minecraft.nix
      ./dev.nix
    ];

    packages = system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ self.overlays.default ];
      };
    in
      pkgs.lib.foldr (a: b: a // b) {} (builtins.map (p: import p {
        inherit pkgs;
        fenix = fenix.packages.${pkgs.system};
      }) modules);

  in {

    overlays.default = pkgs: prev: prev.lib.foldr (a: b: a // b) {} (builtins.map (p: import p {
      inherit pkgs;
      fenix = fenix.packages.${pkgs.system};
    }) modules);

    packages."x86_64-linux" = packages "x86_64-linux";

  };
}
