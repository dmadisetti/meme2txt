{
  description = "Flake to manage python workspace";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/master";
    flake-utils.url = "github:numtide/flake-utils";
    mach-nix.url = "github:DavHau/mach-nix?ref=3.3.0";
  };

  outputs = { self, nixpkgs, flake-utils, mach-nix }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        python = "python39";
        pkgs = import nixpkgs {
          inherit system;
        };
        # https://github.com/DavHau/mach-nix/issues/153#issuecomment-717690154
        mach-nix-wrapper = import mach-nix { inherit pkgs python; };
        requirements = builtins.readFile ./requirements.txt;
        pythonBuild = mach-nix-wrapper.mkPython {
          inherit requirements;
          _."img2txt.py".patches = [ ./nix.patch ];
        };
        # app requirements
        dependencies = [
          pkgs.perl
          pythonBuild
        ];
      in
      {
        devShell = pkgs.mkShell {
          buildInputs = [
            # dev packages
            mach-nix
            (pkgs.${python}.withPackages
              (ps: with ps; [ pip pyflakes ]))
          ];
          packages = dependencies ++ [
            # a bit of fun
            pkgs.toilet
          ];
        };
        defaultPackage =
          pkgs.stdenv.mkDerivation {
            name = "meme2txt";
            src = self;
            propagatedBuildInputs = dependencies;
            installPhase = ''
              mkdir -p $out/bin;
              cp ${pythonBuild}/bin/img2txt.py $out/bin
              cp ${pkgs.perl}/bin/perl $out/bin
              cp meme2txt.sh $out/bin/meme2txt'';
          };
      });
}
