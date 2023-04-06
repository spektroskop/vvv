include ../../tools/Makefile

.PHONY: clean build watch
.DEFAULT_GOAL := build

bundler := ../../bundler
gleam_build := build/dev/javascript/vvv
static_reloader := PATCH http://localhost:3210/static
build := build/bundle

node_modules:
	npm ci

clean:
	make -C $(bundler) clean
	rm -rf build/bundle
	rm -rf node_modules
	gleam clean

build: node_modules
	make -C $(bundler) build/bundler
	mkdir -p $(build)
	cp assets/index.html $(build)/index.html
	$(bundler)/build/bundler --resolve gleam=$(gleam_build) --output $(build) assets/app.js
	@-curl --silent --request $(static_reloader) | $(format_json)

watch:
	watchexec \
	--watch src \
	--watch assets \
	make build
