listen_port := 3210
client_build := ../client/build
config_file := ../vvv.toml

.PHONY: docs
docs:
	gleam docs build
	SERVER_PORT=$(listen_port) \
	STATIC_BASE=build/dev/docs/vvv \
	gleam run

.PHONY: watch
watch:
	CONFIG=$(config_file) \
	SERVER_PORT=$(listen_port) \
	STATIC_RELOADER_METHOD=PATCH \
	STATIC_RELOADER_PATH=static \
	STATIC_BASE=$(client_build) \
	watchexec --restart \
	--watch $(config_file) \
	--watch gleam.toml \
	--watch manifest.toml \
	--watch src \
	gleam run
