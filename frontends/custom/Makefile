.DEFAULT_GOAL := build
.PHONY: clean build watch

bundler := ../../bundler
bundle := build/bundle
build := build/dev/javascript/vvv
reload := PATCH http://localhost:3210/static

node_modules:
	npm ci

clean:
	make -C $(bundler) clean
	rm -rf $(bundle)
	rm -rf node_modules
	gleam clean

build: node_modules
	make -C $(bundler) build/bundler
	mkdir -p $(bundle)
	cp assets/index.html $(bundle)/index.html
	$(bundler)/build/bundler assets/app.js assets/app.css --output $(bundle) \
	--activate tailwind --loader js=jsx --resolve gleam=$(build)
	@-curl --silent --request $(reload) | jq

watch:
	watchexec \
	--watch package.json \
	--watch tailwind.config.js \
	--watch src \
	--watch assets \
	make build