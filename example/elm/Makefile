.PHONY: build

build:
	mkdir -p build
	cp index.html build/index.html
	cp heart.svg build/heart.svg
	./bundler --output build app.js
	tailwind --input app.css --output build/app.css
	-curl -s -X PATCH http://localhost:3210/static

clean:
	rm -rf build
