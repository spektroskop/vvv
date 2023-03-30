.PHONY: run watch docs example

watch := watchexec --restart --watch gleam.toml --watch vvv.toml --watch src
run := gleam run
check := gleam check
config := SERVER_PORT=3210
config_with_file := CONFIG=vvv.toml $(config)

check:
	$(watch) $(check)

run:
	$(config) $(run) 

watch:
	$(config_with_file) $(watch) $(run) 

docs:
	gleam docs build
	STATIC_BASE=build/dev/docs/vvv \
	$(config) $(run)

example:
	make -C example
	STATIC_BASE=example/build \
	$(config) $(run)

