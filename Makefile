watch := watchexec --restart --watch gleam.toml --watch vvv.toml --watch src
run := gleam run
check := gleam check
config := SERVER_PORT=3210
config_with_file := CONFIG=vvv.toml $(config)
reloader := STATIC_RELOADER_METHOD=PATCH STATIC_RELOADER_PATH=static

.PHONY: check
check:
	$(watch) $(check)

.PHONY: run
run:
	$(config) $(run) 

.PHONY: watch
watch:
	$(config_with_file) $(watch) $(run) 

.PHONY: watch-reloader
watch-reloader:
	$(reloader) $(config_with_file) $(watch) $(run) 

.PHONY: docs
docs:
	gleam docs build
	STATIC_BASE=build/dev/docs/vvv \
	$(config) $(run)

.PHONY: example/simple
example/simple:
	STATIC_BASE=example/simple \
	$(config) $(run)

.PHONY: example/elm
example/elm:
	make -C example/elm build
	STATIC_BASE=example/elm/build \
	$(config) $(run)
