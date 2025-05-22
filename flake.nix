{
  description = "flashy elixir flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfreePredicate = pkg:
          builtins.elem (nixpkgs.lib.getName pkg) [
          ];
      };

      inherit (pkgs) inotify-tools terminal-notifier;
      inherit (pkgs.lib) optionals;
      inherit (pkgs.stdenv) isDarwin isLinux;

      linuxDeps = optionals isLinux [inotify-tools];
      darwinDeps =
        optionals isDarwin [terminal-notifier]
        ++ (with pkgs.darwin.apple_sdk.frameworks;
          optionals isDarwin [
            CoreFoundation
            CoreServices
          ]);
    in {
      devShells = {
        default = pkgs.mkShell {
          packages = with pkgs;
            [
              beam.packages.erlang_25.elixir_1_15
            ]
            ++ linuxDeps
            ++ darwinDeps;
          shellHook = ''
            # this allows mix to work on the local directory
            mkdir -p .mix .hex
            export MIX_HOME=$PWD/.mix
            export HEX_HOME=$PWD/.hex
            # make hex from Nixpkgs available
            export PATH=$MIX_HOME/bin:$HEX_HOME/bin:$PATH
            export LANG=C.UTF-8
            # keep your shell history in iex
            export ERL_AFLAGS="-kernel shell_history enabled"
          '';
        };
      };
    });
}
