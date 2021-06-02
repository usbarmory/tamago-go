# Tamago Build

A docker-based build system for cross-compiling Go applications for ARM SoCs.

```bash
$ go install github.com/f-secure-foundry/tamago-go/tamago-build/tbd

$ cd path/to/go/app
$ tbd
Usage: tbd <target-device> [output-path] [path-to-main-package]

$ tbd rpi /Volumes/sd-card cmd/app-name
rpi: Pulling from f-secure-foundry/tamago-go
Status: Image is up to date for f-secure-foundry/tamago-go:rpi
=> Downloading RPi firmware:
   LICENCE.broadcom, bootcode.bin, fixup.dat, start.elf
=> Building Go Application
   go: downloading github.com/f-secure-foundry/tamago v0.0.0-20210601073428-3d51445fa773
=> Preparing kernel file
=> Build successful!
```

## How it works

The `tbd` program is a purpose-built docker client which pulls and runs the tamago-build docker image for the specified target with the appropriate arguments.

The tamago-build docker images are specific to each build target (currently only `rpi` exists). They use tamago-go to compile the given Go application for ARM SoCs, using [multiarch/crossbuild](https://github.com/multiarch/crossbuild) for cross compilation tooling to provide the kernel and boot files needed for the built output to Just Work™. 

## Further work

Potential improvements:

- Add Dockerfiles for the [other supported hardware](https://github.com/f-secure-foundry/tamago#supported-hardware)
- Use a different image for cross-compilation tooling (multiarch/crossbuild is _large_)
