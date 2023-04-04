# vvv

This is my bikeshed laboratory for experimenting with web app development!

## development

### setup

```sh
git submodule update --init
```

### gleam backend

> requires: [Gleam](https://gleam.run), [watchexec](https://github.com/watchexec/watchexec)

```sh
STATIC_BASE=path/to/assets make -C backend watch
```

### frontends

#### static

```sh
STATIC_BASE=$PWD/frontends/static make -C backend watch
```

#### elm

> requires: [Elm](https://elm-lang.org), [Go](https://go.dev), [tailwind cli](https://tailwindcss.com), [watchexec](https://github.com/watchexec/watchexec)

```sh
STATIC_BASE=$PWD/frontends/elm/build make -C backend watch
```

```sh
make -C frontends/elm watch
```

#### lustre

> requires: [Gleam](https://gleam.run), [Go](https://go.dev), [watchexec](https://github.com/watchexec/watchexec)

```sh
STATIC_BASE=$PWD/frontends/lustre/build/bundle make -C backend watch
```

```sh
make -C frontends/lustre watch
```
