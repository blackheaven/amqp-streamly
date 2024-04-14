{
  description = "The amqp-streamly flake";
  inputs.haskellNix.url = "github:input-output-hk/haskell.nix";
  inputs.nixpkgs.follows = "haskellNix/nixpkgs-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  outputs = { self, nixpkgs, flake-utils, haskellNix }:
    flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ] (system:
    let
      overlays = [ haskellNix.overlay
        (final: prev: {
          # This overlay adds our project to pkgs
          amqp-streamlyProject =
            final.haskell-nix.cabalProject' {
              src = ./.;
              compiler-nix-name = "ghc964";
              #evalSystem = "x86_64-linux";
              #index-state = "2024-03-01T00:00:00Z";
              #materialized = ./amqp-streamly.materialized;
              # This is used by `nix develop .` to open a shell for use with
              # `cabal`, `hlint` and `haskell-language-server`
              shell.tools = {
                cabal = {};
                hlint = {};
                haskell-language-server = {};
              };
              # Non-Haskell shell tools go here
              shell.buildInputs = with pkgs; [
                # nixfmt
              ];
              # This adds `js-unknown-ghcjs-cabal` to the shell.
              # shell.crossPlatforms = p: [p.ghcjs];
            };
        })
      ];
      pkgs = import nixpkgs { inherit system overlays; inherit (haskellNix) config; };
      flake = pkgs.amqp-streamlyProject.flake {
        # This adds support for `nix build .#js-unknown-ghcjs:amqp-streamly:exe:amqp-streamly`
        # crossPlatforms = p: [p.ghcjs];
        # for fully static binary
        crossPlatforms = p: [p.musl64];
      };
    in flake // {
      # Built by `nix build .`
      packages.default = flake.packages."amqp-streamly:lib:amqp-streamly";
      packages.amqp-streamly-lib = flake.packages."amqp-streamly:lib:amqp-streamly";
      packages.amqp-streamly-test = flake.packages."amqp-streamly:test:amqp-streamly-test";
    });
  # --- Flake Local Nix Configuration ----------------------------
  nixConfig = {
    # This sets the flake to use the IOG nix cache.
    # Nix should ask for permission before using it,
    # but remove it here if you do not want it to.
    #extra-substituters = ["https://cache.iog.io"];
    #extra-trusted-public-keys = ["hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="];
    allow-import-from-derivation = "true";
  };
}

