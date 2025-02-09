# nix-notes-gentoo-like

Experimenting with Gentoo like features for overriding packages and using
package overlays.

A nice feature over Gentoo is that the used overlay is defined per package, app,
nixos-module, nixos-configuration instead of per host. And its overrides also
reside where they're being used.

## flakes

Flakes have multiple outputs: packages, apps, overlays, development shells,
NixOS modules and configurations.

To show the contents of a flake run `nix flake show`.

To check a flake run `nix flake check`.

## Overriding Packages

In `Gentoo` you usually override packages by replacing/adding stage functions
like `src_prepare()`, adding patches, adding files, et cetera to
`portage config` (`/etc/portage/`). This lets you keep using the upstream
`ebuild` with your local changes. This is like using the `overrideAttrs`
function in `Nix`.

You can also define a new package and replace an old one using the
`pkgs.callPackage` function. This is less desirable since you have to define and
maintain the complete package.

You can also fork an `ebuild` and add to your `repo`/`overlay`, rev-bump it, and
make the necessary changes to it.

The `Nix` preferred method is to use the `overrideAttrs` function because you
only need to maintain your changes to the package vs having to maintain the
whole package.

### Override Package

Passed to the builder function, `stdenv.mkDerivation`.

```nix
# flake.nix
pkgs.callPackage ./default.nix {};

# default.nix
{ lib, stdenv, fetchurl }:
stdenv.mkDerivation rec {
  pname = "hello";
  version = "2.21.1";
  src = fetchurl {
    url = "mirror://gnu/hello/hello-${version}.tar.gz";
    sha256 = "sha256-jZkUKv2SV28wsM18tCqNxoCZmLxdYH2Idh9RLibH2yA=";
  };
}
```

### overrideAttrs Function

Used on the package that's being overridden.

```nix
packages = pkgs.hello.overrideAttrs {
  pname = "goodbye";
};
```

## Overlays

Same principle as Gentoo `repos` or `overlays`. It's a collection of functions
and packages.

Each overlay is defined as a function in the `overlays` list.

```nix
(newNixpkgs: oldNixpkgs: {
  # your overlay is an attribute set accessible from pkgs
})
```

Complete example of a package version override getting added to an overlay and
set as the default package output of the flake.

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs, flake-utils, }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            (final: prev: {
              hello = prev.hello.overrideAttrs (oldAttrs: rec {
                version = "2.11"; # the current version is >=2.12.1
                src = pkgs.fetchurl {
                  url = "mirror://gnu/hello/hello-${version}.tar.gz";
                  hash = "sha256-jJzgVy08RO0GcOsc3pgFhOA4tvYsJf396O8SjeFQBL0=";
                };
              });
            })
          ];
        };
      in {
        packages = {
          hello = pkgs.hello;
          default = pkgs.hello;
        };
      }
    );
}
```

### Override Demos

#### 3 versions of hello

The `flake.nix` derivation uses `overrideAttrs and overlays to add two older
versions of the program.

To run a specific package in the flake, use the `repo#name` notation.

```text
$ nix run . -- --version
hello (GNU Hello) 2.12.1
Copyright (C) 2020 Free Software Foundation, Inc.
License GPLv3+: GNU GPL version 3 or later <https://gnu.org/licenses/gpl.html>.
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.

Written by Karl Berry, Sami Kerola, Jim Meyering,
and Reuben Thomas.
```

```text
$ nix run .#hello-2_11_0 -- --version
hello (GNU Hello) 2.11
Copyright (C) 2020 Free Software Foundation, Inc.
License GPLv3+: GNU GPL version 3 or later <https://gnu.org/licenses/gpl.html>.
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.

Written by Karl Berry, Sami Kerola, Jim Meyering,
and Reuben Thomas.
```

```text
$ nix run .#hello-2_10_0 -- --version
hello (GNU Hello) 2.10

Copyright (C) 2014 Free Software Foundation, Inc.
License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.
```
