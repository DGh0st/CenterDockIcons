export ARCHS = armv7 arm64
export TARGET = iphone:clang:latest:latest

FINALPACKAGE = 1

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = CenterDockIcons
CenterDockIcons_FILES = Tweak.xm

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
