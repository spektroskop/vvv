.PHONY: build
build: ../bundler/bundler
	mkdir -p build
	cp assets/index.html build/index.html
	cp assets/heart.svg build/heart.svg
	../bundler/bundler --output build assets/app.js assets/app.css
	-curl -s -X PATCH http://localhost:3210/static
	@echo

../bundler/bundler:
	cd ../bundler && go build -v ./cmd/bundler

.PHONY: watch
watch:
	watchexec \
	--watch elm.json \
	--watch tailwind.config.js \
	--watch src \
	--watch assets \
	make build

.PHONY: clean
clean:
	rm -f ../bundler/bundler
	rm -rf build
