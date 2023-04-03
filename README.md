# vvv

This is a template repository for things I usually need when writing web applications.

Languages and tools used in this repo:

- [Gleam](https://gleam.run)
- [Elm](https://elm-lang.org)
- [Go](https://go.dev)
- [esbuild](https://github.com/evanw/esbuild)
- [tailwind](https://tailwindcss.com)
- [watchexec](https://github.com/watchexec/watchexec)

## configuration

Backend configuration is provided either through a config file or the environment. See `vvv.toml` for all the configuration options, their defaults, and corresponding environment variable names.

## running

If you want to use an environment prefix it must be passed as a command line argument. 

The `CONFIG` variable sets the path to the config file to use. 

`SERVER_PORT` and `STATIC_BASE` must be defined, either in the environment or in the config file.

### general syntax

```
[$PREFIX]_SERVER_PORT=$PORT \
[$PREFIX]_STATIC_BASE=$PATH \
[$PREFIX]_CONFIG=$PATH \
gleam run [$PREFIX]
```

### start the server

```sh
SERVER_PORT=3210 \
STATIC_PATH=some/path \
gleam run
```

### activate reloader

```sh
SERVER_PORT=3210 \
STATIC_BASE=some/path \
STATIC_RELOADER_METHOD=PATCH \
STATIC_RELOADER_PATH=static \
gleam run
```

### reload assets

```sh
curl --request PATCH localhost:3210/static
```

### get current asset hashes

```sh
curl localhost:3210/api/assets
```

## development

### setup

```sh
git submodule update --init
```

### backend

```sh
STATIC_BASE=$PWD/frontends/elm/build make -C backend watch
```

### frontend

```sh
make -C frontends/elm watch
```
