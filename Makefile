NODE_PATH := ./node_modules
PATH := ./node_modules/.bin:${PATH}

init:
	npm bundle

clean-css:
	rm -f public/*.css

clean: clean-css

dist-clean: clean
	npm bundle destroy

build-client:
	coffee -o public client/*.coffee

# For Gunnar
build-css:
	stylus -o public views/styles/main.styl

dist: clean init build-client build-css
