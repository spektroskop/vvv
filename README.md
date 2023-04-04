# vvv

This is my bikeshed laboratory for experimenting with web app development!

Languages and tools currently used in this repo:

- [Gleam](https://gleam.run) — backend
- [Elm](https://elm-lang.org) — frontend
- [Go](https://go.dev) — bundler
- [esbuild](https://github.com/evanw/esbuild) — bundler
- [tailwind](https://tailwindcss.com) — styling
- [watchexec](https://github.com/watchexec/watchexec) — development

## development

### setup

```sh
git submodule update --init
```

### gleam backend

```sh
STATIC_BASE=$PWD/frontends/elm/build make -C backend watch
```

### elm frontend

```sh
make -C frontends/elm watch
```
