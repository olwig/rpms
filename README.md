# rpms

This repository contains my RPM packaging work, mainly Fedora/COPR packaging for software I use.

At the moment it includes:

- `onekey-wallet-bin` [![Copr build status](https://copr.fedorainfracloud.org/coprs/olafwriggers/onekey-wallet-bin/package/onekey-wallet-bin/status_image/last_build.png)](https://copr.fedorainfracloud.org/coprs/olafwriggers/onekey-wallet-bin/package/onekey-wallet-bin/)

## What this repo is for

- keeping RPM spec files and packaging-related files in one place
- testing building packages for COPR
- tracking upstream releases with the GitHub Actions

## How to use it

- package definitions live in `packages/onekey-wallet-bin/`
- COPR helper files live in `.copr/`
- to inspect or update a package, start with its `.spec` file
- to build an SRPM for COPR, use the target from `.copr/Makefile`
