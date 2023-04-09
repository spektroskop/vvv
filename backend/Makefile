.DEFAULT_GOAL := build
.PHONY: build docs watch

listen_port := 3210
config_file := vvv.toml

build:

docs:
	gleam docs build
	SERVER_PORT=$(listen_port) \
	STATIC_BASE=build/dev/docs/vvv \
	gleam run

watch:
	CONFIG=$(config_file) \
	SERVER_PORT=$(listen_port) \
	STATIC_RELOADER_METHOD=PATCH \
	STATIC_RELOADER_PATH=static \
	watchexec --restart \
	--watch $(config_file) \
	--watch gleam.toml \
	--watch manifest.toml \
	--watch src \
	gleam run
