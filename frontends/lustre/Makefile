ifneq (, $(shell which jq))
	format_json := jq
else
	format_json := cat && echo
endif

.PHONY: clean build watch
.DEFAULT_GOAL := build

bundler := ../../bundler
static_reloader := PATCH http://localhost:3210/static
build := build/bundle

clean:
	make -C $(bundler) clean
	rm -rf build/bundle

build:
	make -C $(bundler) build/bundler
	mkdir -p $(build)
	cp assets/index.html $(build)/index.html
	gleam build --target=javascript
	$(bundler)/build/bundler --output $(build) assets/app.js
	@-curl --silent --request $(static_reloader) | $(format_json)
