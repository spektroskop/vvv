# vvv

This is my bikeshed laboratory for experimenting with web app development!

Languages and tools currently used in this repo:

- [Gleam](https://gleam.run)
- [Elm](https://elm-lang.org)
- [Go](https://go.dev)
- [esbuild](https://github.com/evanw/esbuild)
- [tailwind](https://tailwindcss.com)
- [watchexec](https://github.com/watchexec/watchexec)

## development

### setup

```sh
git submodule update --init
```

### gleam backend

```sh
STATIC_BASE=path/to/assets make -C backend watch
```

### frontends

#### static

```sh
STATIC_BASE=$PWD/frontends/static make -C backend watch
```

#### elm

```sh
STATIC_BASE=$PWD/frontends/elm/build make -C backend watch
```

```sh
make -C frontends/elm watch
```

#### lustre

```sh
STATIC_BASE=$PWD/frontends/lustre/build/bundle make -C backend watch
```

```sh
make -C frontends/lustre watch
```
