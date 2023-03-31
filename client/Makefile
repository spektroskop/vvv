.PHONY: build
build: ../bundler/bundler
	mkdir -p build
	cp index.html build/index.html
	cp heart.svg build/heart.svg
	../bundler/bundler --output build app.js
	tailwind --input app.css --output build/app.css
	-curl -s -X PATCH http://localhost:3210/static | jq -c .

../bundler/bundler:
	cd ../bundler && go build -v ./cmd/bundler

.PHONY: watch
watch:
	watchexec \
	--watch tailwind.config.js \
	--watch index.html \
	--watch app.js \
	--watch app.css \
	--watch src \
	make build

.PHONY: clean
clean:
	rm -f ../bundler/bundler
	rm -rf build
