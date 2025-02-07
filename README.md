# nix-notes-gentoo-like

Experimenting with Gentoo like features for overriding packages and using
package overlays.

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
