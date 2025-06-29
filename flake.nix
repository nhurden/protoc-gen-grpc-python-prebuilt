{
  description = "Development environment for protoc-gen-grpc-python-prebuilt";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            act # GitHub Actions runner for local testing
            shellcheck # Shell script analysis tool
            uv # Python package manager
          ];

          shellHook = ''
            echo "🚀 protoc-gen-grpc-python-prebuilt development environment"
            echo ""
            echo "Available tools:"
            echo "  - act: $(act --version 2>/dev/null || echo 'GitHub Actions local runner')"
            echo "  - uv: $(uv --version 2>/dev/null || echo 'Python package manager')"
            echo ""
            echo "Usage:"
            echo "  act push -W .github/workflows/build-and-release.yml --job build"
            echo "  uv run scripts/update-versions.py --dry-run"
            echo ""
          '';
        };
      }
    );
}
