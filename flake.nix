{
    description = "Gathio: ephemeral event pages for the fediverse";

    inputs.nixpkgs = {
        url = github:nixos/nixpkgs/nixos-22.11;
    };

    inputs.flake-utils = {
        url = github:numtide/flake-utils;
        inputs.nixpkgs.follows = "nixpkgs";
    };

    outputs = { self, nixpkgs, flake-utils, ... }:
      flake-utils.lib.eachDefaultSystem (system:
        let
          pkgs = import nixpkgs { inherit system; };
          nodeDependencies = (pkgs.callPackage ./default.nix {}).shell.nodeDependencies;
          pname = "gathio";
          nodejs = pkgs.nodejs-18_x;

          nativeBuildInputs = with pkgs; [
            nodejs-18_x
            nodePackages.yarn
            makeWrapper
          ];

          yarnPkg = pkgs.mkYarnPackage rec {
            inherit pname nativeBuildInputs;
            src = ./.;
            packageJSON = ./package.json;
            yarnLock = ./yarn.lock;

            buildPhase = ''
              yarn --offline --build-from-source build
            '';

            doCheck = false;

            postInstall = ''
              makeWrapper '${nodejs}/bin/node' "$out/bin/${pname}" \
                --add-flags "$out/${passthru.nodeAppDir}/build/index.js"
            '';

            distPhase = ''
              true
            '';

            passthru = {
                nodeAppDir = "libexec/${pname}/deps/${pname}";
            };
          };
        in rec
        {

            defaultPackage = yarnPkg;
            packages.${system}.${pname} = yarnPkg;

            defaultApp = {
                drv = self.defaultPackage;
            };

            apps.${pname} = defaultApp;

            devShells.${system}.default = pkgs.mkShell {
                inherit nativeBuildInputs;
            };
        }
    );
}
