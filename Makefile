PROJECT   := RiveViewer.xcodeproj
SCHEME    := RiveViewer
DERIVED   := build
KIT       := Packages/RiveViewerKit

.PHONY: project test build release install preview clean

project:
	xcodegen generate

test:
	cd $(KIT) && swift test

build: project
	@echo "make build is defined in Task 4"

release: project
	@echo "make release is defined in Task 4"

install:
	@echo "make install is defined in Task 4"

preview:
	@echo "make preview FILE=path.riv is defined in Task 4"

clean:
	rm -rf $(DERIVED) $(KIT)/.build
