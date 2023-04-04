# vvv

This is my bikeshed laboratory for experimenting with web app development!

## development

### setup

Fetch [bundler](https://github.com/spektroskop/bundler) component

```sh
git submodule update --init
```

### gleam backend

> requires: [gleam](https://gleam.run), [watchexec](https://github.com/watchexec/watchexec)

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

> requires: [elm](https://elm-lang.org), [go](https://go.dev), [tailwind cli](https://tailwindcss.com), [watchexec](https://github.com/watchexec/watchexec)

```sh
make -C frontends/elm watch
```

#### [lustre](https://github.com/hayleigh-dot-dev/gleam-lustre)

```sh
STATIC_BASE=$PWD/frontends/lustre/build/bundle make -C backend watch
```

> requires: [gleam](https://gleam.run), [go](https://go.dev), [watchexec](https://github.com/watchexec/watchexec)

```sh
make -C frontends/lustre watch
```
