{
  outputs = { self }: {

    overlays.default = pkgs: prev: import ./vr.nix { pkgs = prev; };

  };
}
