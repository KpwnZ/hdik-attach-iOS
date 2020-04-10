ARCHS = arm64 arm64e
include $(THEOS)/makefiles/common.mk

TOOL_NAME = hdik

hdik_FILES = main.mm
hdik_CFLAGS = -fobjc-arc
hdik_FRAMEWORKS = IOKit
hdik_CODESIGN_FLAGS = -Shdik.plist

include $(THEOS_MAKE_PATH)/tool.mk
