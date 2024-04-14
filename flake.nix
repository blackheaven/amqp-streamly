{
  description = "amqp-streamly";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        haskellPackages = pkgs.haskellPackages;

        jailbreakUnbreak = pkg:
          pkgs.haskell.lib.doJailbreak (pkgs.haskell.lib.dontCheck (pkgs.haskell.lib.unmarkBroken pkg));
      in
      rec
      {
        packages.amqp-streamly =
          pkgs.haskell.lib.dontCheck
            (haskellPackages.callCabal2nix "amqp-streamly" ./. {
              testcontainers = jailbreakUnbreak haskellPackages.testcontainers;
            });

        defaultPackage = pkgs.linkFarmFromDrvs "all-amqp-streamly" (pkgs.lib.unique (builtins.attrValues packages));


        devShell = pkgs.mkShell {
          buildInputs = with haskellPackages; [
            haskell-language-server
            ghcid
            cabal-install
            haskell-ci
          ];
          inputsFrom = builtins.attrValues self.packages.${system};
        };
      });
}
