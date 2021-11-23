.PHONY: setup clean arch project log mocks
setup:
	brew bundle
clean:
	rm -rf .build
	rm -rf WarningSample.xcodeproj
project:
	rm -rf WarningSample.xcodeproj
	xcodegen generate