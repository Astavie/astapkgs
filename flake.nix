{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  inputs.fenix.url = "github:nix-community/fenix";
  inputs.fenix.inputs.nixpkgs.follows = "nixpkgs";

  outputs = { self, nixpkgs, fenix }: let

    modules = [
      ./wivrn.nix
      ./minecraft.nix
      ./dev.nix
      ./discord.nix
    ];

    system-pkgs = system: import nixpkgs {
      inherit system;
      overlays = [ self.overlays.default ];
    };

    system-packages = system: let
      pkgs = system-pkgs system;
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

    packages."x86_64-linux" = system-packages "x86_64-linux";

    lib.package = { package ? null, devShell ? null }: systems: {
      overlays.default = _: pkgs: let
        pkg = package pkgs;
      in {
        ${pkg.pname} = pkg;
      };
      packages = builtins.listToAttrs (builtins.map (system: {
        name = system;
        value.default = package (system-pkgs system);
      }) systems);
      devShells = builtins.listToAttrs (builtins.map (system: {
        name = system;
        value.default = devShell (system-pkgs system);
      }) systems);
    };

  };
}
