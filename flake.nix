{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      pkgs = forAllSystems (system: nixpkgs.legacyPackages.${system});

      mkOverrides = system:
        (self: super: {
          altgraph = super.altgraph.overridePythonAttrs (old: { buildInputs = (old.buildInputs or [ ]) ++ [ super.setuptools ]; });
          macholib = super.macholib.overridePythonAttrs (old: { buildInputs = (old.buildInputs or [ ]) ++ [ super.setuptools ]; });
          pyinstaller = super.pyinstaller.overridePythonAttrs (old: { buildInputs = (old.buildInputs or [ ]) ++ [ super.setuptools ]; });
          pyinstaller-hooks-contrib = super.pyinstaller-hooks-contrib.overridePythonAttrs (old: { buildInputs = (old.buildInputs or [ ]) ++ [ super.setuptools ]; });
          numpy = pkgs.${system}.python3Packages.numpy;
          matplotlib = pkgs.${system}.python3Packages.matplotlib;
          packaging = pkgs.${system}.python3Packages.packaging;
          black = pkgs.${system}.python3Packages.black;
          tomli = pkgs.${system}.python3Packages.tomli;
        });
    in
    {
      apps = forAllSystems
        (system: {
          default = {
            type = "app";
            program = self.packages.${system}.default + "/bin/preprocess_cancellation";
          };
        });

      packages = forAllSystems
        (system: {
          default = pkgs.${system}.poetry2nix.mkPoetryApplication
            {
              projectDir = self;
              overrides = pkgs.${system}.poetry2nix.defaultPoetryOverrides.extend (mkOverrides system);
            };
        });

      devShells = forAllSystems (system: {
        default = pkgs.${system}.mkShellNoCC {
          packages = with pkgs.${system}; [
            (poetry2nix.mkPoetryEnv {
              projectDir = self;
              overrides = pkgs.${system}.poetry2nix.defaultPoetryOverrides.extend (mkOverrides system);
            })
            poetry
          ];
        };
      });
    };
}
