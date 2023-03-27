.PHONY: run watch docs example

watch := watchexec --restart --watch gleam.toml --watch vvv.toml --watch src
run := gleam run
config := CONFIG=vvv.toml SERVER_PORT=3210

run:
	$(config) $(run) 

watch:
	$(config) $(watch) $(run) 

docs:
	gleam docs build
	STATIC_BASE=build/dev/docs/vvv \
	$(config) $(run)

example:
	STATIC_BASE=example \
	$(config) $(run)

