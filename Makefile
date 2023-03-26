.PHONY: watch

watch := watchexec --restart --watch gleam.toml --watch vvv.toml --watch src
run := gleam run

watch:
	CONFIG=vvv.toml SERVER_PORT=3210 $(watch) $(run) 
