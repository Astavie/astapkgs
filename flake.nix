{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  inputs.fenix.url = "github:nix-community/fenix";
  inputs.fenix.inputs.nixpkgs.follows = "nixpkgs";

  outputs = { self, nixpkgs, fenix }: let

    system-nixpkgs = system: import nixpkgs {
      inherit system;
    };

    system-astapkgs = nixpkgs: let
      fenixpkgs = fenix.packages.${nixpkgs.system};
      astapkgs = self.packages.${nixpkgs.system};
    in 
      import ./dev.nix { inherit nixpkgs astapkgs; fenix = fenixpkgs; } //
      import ./wivrn.nix { inherit nixpkgs; } //
      import ./minecraft.nix { inherit nixpkgs; } //
      { };

    system-pkgs = system: import nixpkgs {
      inherit system;
      overlays = [ self.overlays.default ];
    };

  in {

    overlays.default = pkgs: prev: system-astapkgs prev;
    packages."x86_64-linux" = system-astapkgs (system-nixpkgs "x86_64-linux");

    lib.package = { name ? null, package ? null, devShell ? null }: systems: {
      overlays.default = _: pkgs: let
        pkg = package pkgs;
      in {
        ${name} = pkg;
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
