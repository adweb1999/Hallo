THEOS_DEVICE_IP = 192.168.1.1
ARCHS = arm64 arm64e
TARGET := iphone:clang:latest:14.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = OneStateLogin

OneStateLogin_FILES = Tweak.xm
OneStateLogin_CFLAGS = -fobjc-arc
OneStateLogin_LDFLAGS = -framework UIKit -framework Foundation

include $(THEOS_MAKE_PATH)/tweak.mk
