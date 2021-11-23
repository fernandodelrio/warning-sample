.PHONY: setup project
setup:
	brew bundle
	bundle install
project:
	xcodegen generate
