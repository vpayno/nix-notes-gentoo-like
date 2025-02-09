{
  description = "Nixos config flake with multiple overlays";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
  # let's support all the default systems
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {
          # instead of `system = "x86_64-linux";`
          inherit system; # think of it as `import system`
          overlays = [
            (final: prev: {
              # if we wanted to use at least this version or newer if it's upstream
              # hello = (if self.lib.versionAtLeast super.hello.version "2.12.1" then super.hello else ( prev.hello.overrideAttrs (oldAttrs: rec {

              # usually this would be set set to hello= but I want multiple versions at the same time
              hello-2_11_0 = prev.hello.overrideAttrs (oldAttrs: rec {
                version = "2.11"; # the current version is >=2.12.1, warning, source tarball for 2.12 is bad
                src = pkgs.fetchurl {
                  url = "mirror://gnu/hello/hello-${version}.tar.gz";
                  hash = "sha256-jJzgVy08RO0GcOsc3pgFhOA4tvYsJf396O8SjeFQBL0=";
                };
              });

              hello-2_10_0 = prev.hello.overrideAttrs (oldAttrs: rec {
                version = "2.10"; # the current version is >=2.12.1, warning, source tarball for 2.12 is bad
                src = pkgs.fetchurl {
                  url = "mirror://gnu/hello/hello-${version}.tar.gz";
                  hash = "sha256-MeBmE3qWJnbon2nRtlOC3pWn732RS4y5VvQepy4PUWs=";
                };
              });

              # keep hello at the latest version
              hello = prev.hello;
            })
          ];
        };

        sharedDevPkgs = with pkgs; [
          bashInteractive
          coreutils
          cowsay
          git
          glow
          moreutils
          runme
        ];
      in {
        formatter = pkgs.nixfmt-rfc-style;

        # instead of packages.x86_64-linux.default
        packages = {
          hello = pkgs.hello;
          default = pkgs.hello;
          hello-2_10_0 = pkgs.hello-2_10_0;
          hello-2_11_0 = pkgs.hello-2_11_0;
        };

        devShells = {
          default = pkgs.mkShell {
            packages = [pkgs.hello] ++ sharedDevPkgs;
          };

          hello210 = pkgs.mkShell {
            packages = [pkgs.hello-2_10_0] ++ sharedDevPkgs;
          };

          hello211 = pkgs.mkShell {
            packages = [pkgs.hello-2_11_0] ++ sharedDevPkgs;
          };
        };
      }
    );
}
