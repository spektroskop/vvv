.DEFAULT_GOAL := build
.PHONY: clean build watch

bundler := ../../bundler
bundle := build/bundle
build := build/dev/javascript/vvv
reload := PATCH http://localhost:3210/static

clean:
	make -C $(bundler) clean
	rm -rf $(bundle)
	gleam clean

build:
	make -C $(bundler) build/bundler
	mkdir -p $(bundle)
	cp assets/index.html $(bundle)/index.html
	$(bundler)/build/bundler assets/app.js assets/app.css --output $(bundle) \
	--activate tailwind --resolve gleam=$(build)
	@-curl --silent --request $(reload) | jq

watch:
	watchexec \
	--watch tailwind.config.js \
	--watch src \
	--watch assets \
	make build
