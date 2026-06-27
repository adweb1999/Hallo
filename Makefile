THEOS_DEVICE_IP = 192.168.1.1
ARCHS = arm64 arm64e
TARGET := iphone:clang:latest:14.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Login

Login_FILES = Tweak.xm
Login_CFLAGS = -fobjc-arc
Login_LDFLAGS = -framework UIKit -framework Foundation

include $(THEOS_MAKE_PATH)/tweak.mk
