{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  inputs.fenix.url = "github:nix-community/fenix";
  inputs.fenix.inputs.nixpkgs.follows = "nixpkgs";

  outputs = { self, nixpkgs, fenix }: let

    system-nixpkgs = system: import nixpkgs {
      inherit system;
    };

    system-astapkgs = nixpkgs: let
      astapkgs = self.packages.${nixpkgs.system};
    in 
      import ./dev.nix { inherit nixpkgs astapkgs fenix; } //
      import ./wivrn.nix { inherit nixpkgs; } //
      import ./minecraft.nix { inherit nixpkgs; } //
      import ./discord.nix { inherit nixpkgs; } //
      { };

  in {

    overlays.default = pkgs: prev: system-astapkgs prev;
    packages."x86_64-linux" = system-astapkgs (system-nixpkgs "x86_64-linux");

  };
}
