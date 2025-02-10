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

### DevShell Demos

`nix develop` is a shell that exposes the package build step functions. It can
also be used as the development shell for the project.

If you need to use older versions of a program, `devbox` can be easier to use
because you just have to specify an older version of a program that they have.
Otherwise, you have to do the work to add an override to the overlay and the
`devShell`.

The `flake.nix` derivation uses overrideAttrs and overlays to add two older
versions of the program and adds them to their respective `devShell`.

```text
$ nix develop

$ which hello
/nix/store/p09fxxwkdj69hk4mgddk4r3nassiryzc-hello-2.12.1/bin/hello

$ hello --version
hello (GNU Hello) 2.12.1
Copyright (C) 2020 Free Software Foundation, Inc.
License GPLv3+: GNU GPL version 3 or later <https://gnu.org/licenses/gpl.html>.
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.

Written by Karl Berry, Sami Kerola, Jim Meyering,
and Reuben Thomas.
```

```text
$ nix develop .#hello211

$ which hello
/nix/store/d64iwdk9i1af07cys6675y9ijsgdscwj-hello-2.11/bin/hello

$ hello --version
hello (GNU Hello) 2.11
Copyright (C) 2020 Free Software Foundation, Inc.
License GPLv3+: GNU GPL version 3 or later <https://gnu.org/licenses/gpl.html>.
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.

Written by Karl Berry, Sami Kerola, Jim Meyering,
and Reuben Thomas.

$ echo ${PATH} | tr ':' '\n'
/nix/store/d64iwdk9i1af07cys6675y9ijsgdscwj-hello-2.11/bin
/nix/store/6vpzxqaqvwiyqywssfavs1s51b4cgsin-bash-interactive-5.2p37/bin
/nix/store/wdap4cr3bnm685f27y9bb6q5b6q18msl-coreutils-9.5/bin
/nix/store/hz54jclm6r8dafgi4cwr0dmc7knhg9qd-cowsay-3.8.4/bin
/nix/store/33g65w5cc9n8fr0hxj84282xmv4l7hyl-git-2.47.2/bin
/nix/store/idp2zz9f81mzpi4pij6l5nv2lbn4dh4q-glow-2.0.0/bin
/nix/store/hmixh88rjl67gapl5xg6mpfvwlwrz41s-moreutils-0.70/bin
/nix/store/i0ibdw7smjlm8ldr24w5vkv01cfc7bch-runme-3.8.3/bin
/nix/store/f04zhapn8n8w6yrd35s8sd9qmjp8g9ry-patchelf-0.15.0/bin
/nix/store/4ijy8jbsiqmj37avrk83gn2m903486mr-gcc-wrapper-14-20241116/bin
/nix/store/zs2gq6fkglrd28g1nxlb8waqq37cdc2z-gcc-14-20241116/bin
/nix/store/9lcg6rsqbmx6s35jzy86b86pkj0qhxjl-glibc-2.40-66-bin/bin
/nix/store/vrkxj51s4a1awh7m4p4f1w29wad5s20m-binutils-wrapper-2.43.1/bin
/nix/store/5h5ghy2qf6l91l52j6m5vx473zi38vc3-binutils-2.43.1/bin
/nix/store/wdap4cr3bnm685f27y9bb6q5b6q18msl-coreutils-9.5/bin
/nix/store/032xw8dchwjipwqh6b3h70yc3mcmsqld-findutils-4.10.0/bin
/nix/store/dd7xqz1qwl0di4zb8rzj7r1ds8np9xqs-diffutils-3.10/bin
/nix/store/bffnm1211li6y431irplzbjbccr0k884-gnused-4.9/bin
/nix/store/4lbfasv335vpk8rbcf3pgkag4rhg8jx8-gnugrep-3.11/bin
/nix/store/xpzl2sf58fqfpl64b1fy1ihxay7k71li-gawk-5.3.1/bin
/nix/store/zlmk040fc3jax9s3gldwp5rfwc1hhajc-gnutar-1.35/bin
/nix/store/chwdy9qaxd13q8zvl0zd5r7ql2q116di-gzip-1.13/bin
/nix/store/hpppxlcfvjzrvvcvhcm47divp65gbwq1-bzip2-1.0.8-bin/bin
/nix/store/y0akgyz13jgxwm968bs8kay47zbxx638-gnumake-4.4.1/bin
/nix/store/fd118hwh7d1ncib4mdw56ylv3g9k0iyj-bash-5.2p37/bin
/nix/store/apqwjgbjj646wk2jkzr67l26djamn481-patch-2.7.6/bin
/nix/store/rrv4bd5i7rp2m7j8ix4kl8bzijhh8gd3-xz-5.6.3-bin/bin
/nix/store/qraqns84wjffzd8d3dgbdcyxg41czbd6-file-5.46/bin
/home/vpayno/.nix-profile/bin
/nix/var/nix/profiles/default/bin
/home/vpayno/.local/bin
/home/vpayno/bin
/usr/local/bin
/usr/bin
/bin
```

## Devbox Shell

Using [devbox](https://github.com/jetify-com/devbox) instead of `dev-containers`
this year.

Benefits over dev containers?

- Tooling is less complicated.
- It's also easier/faster to make changes and "redeploy".
- Sets up a Python virtualenv in the root of the project that you can use to
  install packages with pip when they aren't available in Nix or for
  local/private dependencies you haven't added a flake.nix file to.

Benefits over `nix shell` or `nix develop`?

- Easy way to start using Nix!
- Builtin multiple versions for packages.
- No `Nix` code to edit, just edit `devbox.json` or use the `devbox add` or
  `devbox rm` commands to edit dependencies.
- Sets up a Python virtualenv in the root of the project that you can use to
  install packages with pip when they aren't available in Nix or for
  local/private dependencies you haven't added a flake.nix file to.

### Devbox Install

[Install and setup instructions can be found here.](https://github.com/jetify-com/devbox?tab=readme-ov-file#installing-devbox)

```bash { name=setup-00-devbox-show-installed excludeFromRunAll=true }
devbox update
devbox list
```

### Devbox Help

- use `devbox search name` to search for packages
- use `devbox info name` to show the info for a package
- use `devbox add name` to add a package to the shell
- use `devbox update` to update the lock file and environemnt
- use `devbox shell` to start the `nix-shell`
- use `devbox run command` to run a command inside the `nix-shell`

## RunMe Playbook

This and other readme files in this repo are RunMe Playbooks.

Use this playbook step/task to update the [RunMe](https://runme.dev) CLI.

You don't need to install `runme` locally, it's already in the `devbox` shell.

Either run `runme` using `devbox run`:

```bash
devbox run runme
```

or by starting an interactive `devbox shell`:

```bash
devbox shell
runme
```
