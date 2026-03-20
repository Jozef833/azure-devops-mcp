{
  description = "Nix packaging of Microsoft's Azure DevOps MCP server";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    git-hooks-nix = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.git-hooks-nix.flakeModule
      ];

      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      perSystem =
        { config, pkgs, ... }:
        let
          azure-devops-mcp = pkgs.buildNpmPackage rec {
            pname = "azure-devops-mcp";
            version = "2.5.0";

            src = pkgs.fetchFromGitHub {
              owner = "microsoft";
              repo = "azure-devops-mcp";
              tag = "v${version}";
              hash = "sha256-tIIPKjxAp5+rnl+WCfGaSlMt71A+v2Saq/E+pinBJqU=";
            };

            npmDepsHash = "sha256-I8eCzTXjOw+91aOTcO5L5Ha4s59E2oJ69jpl+8aZij8=";

            npmBuildScript = "build";

            meta = {
              description = "MCP server for Azure DevOps";
              homepage = "https://github.com/microsoft/azure-devops-mcp";
              license = pkgs.lib.licenses.mit;
              mainProgram = "mcp-server-azuredevops";
            };
          };
        in
        {
          packages = {
            inherit azure-devops-mcp;
            default = azure-devops-mcp;
          };

          pre-commit.settings.hooks = {
            nixfmt.enable = true;
            deadnix.enable = true;
            statix.enable = true;
          };

          devShells.default = pkgs.mkShell {
            shellHook = ''
              ${config.pre-commit.shellHook}
            '';
            packages = config.pre-commit.settings.enabledPackages;
          };
        };
    };
}
