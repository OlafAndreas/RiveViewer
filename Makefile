PROJECT    := RiveViewer.xcodeproj
SCHEME     := RiveViewer
DERIVED    := build
KIT        := Packages/RiveViewerKit
APP_NAME   := RiveViewer.app
INSTALL_DIR := $(HOME)/Applications
LSREGISTER := /System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister
XCODEBUILD := xcodebuild -project $(PROJECT) -scheme $(SCHEME) -derivedDataPath $(DERIVED) -quiet

.PHONY: project test build release install register preview clean

project:
	xcodegen generate

test:
	cd $(KIT) && swift test

build: project
	$(XCODEBUILD) -configuration Debug build

release: project
	$(XCODEBUILD) -configuration Release build

# Copies the Release build to ~/Applications and tells LaunchServices, PlugInKit and Quick Look about it.
install: release
	-pluginkit -r "$(DERIVED)/Build/Products/Debug/$(APP_NAME)/Contents/PlugIns/RiveQuickLook.appex" 2>/dev/null
	-pluginkit -r "$(DERIVED)/Build/Products/Debug/$(APP_NAME)/Contents/PlugIns/RiveThumbnail.appex" 2>/dev/null
	-$(LSREGISTER) -u "$(DERIVED)/Build/Products/Debug/$(APP_NAME)" >/dev/null 2>&1
	rm -rf "$(INSTALL_DIR)/$(APP_NAME)"
	mkdir -p "$(INSTALL_DIR)"
	cp -R "$(DERIVED)/Build/Products/Release/$(APP_NAME)" "$(INSTALL_DIR)/"
	$(MAKE) register APP="$(INSTALL_DIR)/$(APP_NAME)"

# Registers an app bundle (default: the Debug build) so Quick Look picks up its extension.
APP ?= $(DERIVED)/Build/Products/Debug/$(APP_NAME)
register:
	$(LSREGISTER) -f "$(APP)"
	pluginkit -a "$(APP)/Contents/PlugIns/RiveQuickLook.appex"
	pluginkit -a "$(APP)/Contents/PlugIns/RiveThumbnail.appex"
	qlmanage -r
	qlmanage -r cache

# Opens a Quick Look panel for FILE using the registered extension.
preview:
	qlmanage -p "$(FILE)"

clean:
	rm -rf $(DERIVED) $(KIT)/.build
