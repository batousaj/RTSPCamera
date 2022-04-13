##### Change the following for your environment:
# **Note: You must install the relevant "Command line tools (OSX *.*) for Xcode - Xcode *.*"
# for this configuration file to work.
#
# Change the following version number, if necessary, before running "genMakefiles iphoneos"
IOS_VERSION = 14.0

DEVELOPER_PATH =  /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer
TOOL_PATH = $(DEVELOPER_PATH)/usr/bin
SDK_PATH = $(DEVELOPER_PATH)/SDKs
SDK = $(SDK_PATH)/iPhoneOS$(IOS_VERSION).sdk
COMPILE_OPTS =          $(INCLUDES) -I/usr/local/include -I. $(EXTRA_LDFLAGS) -DBSD=1 -O2 -DSOCKLEN_T=socklen_t -DHAVE_SOCKADDR_LEN=1 -D_LARGEFILE_SOURCE=1 -D_FILE_OFFSET_BITS=64 -DNO_OPENSSL=1 -DNEED_XLOCALE_H=1 -fPIC -arch arm64 --sysroot=$(SDK)
C =                     c
C_COMPILER =            /usr/bin/xcrun clang
C_FLAGS =               $(COMPILE_OPTS)
CPP =                   cpp
CPLUSPLUS_COMPILER =    /usr/bin/xcrun clang
CPLUSPLUS_FLAGS =       $(COMPILE_OPTS) -Wall
OBJ =                   o
LINK =                  /usr/bin/xcrun clang -o 
LINK_OPTS =             -v -L. -arch arm64 --sysroot=$(SDK) -L$(SDK)/usr/lib/system /usr/lib/libc++.dylib
CONSOLE_LINK_OPTS =     $(LINK_OPTS)
LIBRARY_LINK =          /usr/bin/xcrun libtool -static -o 
LIBRARY_LINK_OPTS =
LIB_SUFFIX =            a
LIBS_FOR_CONSOLE_APPLICATION = 
LIBS_FOR_GUI_APPLICATION =
EXE = 
##### End of variables to change

LIVEMEDIA_DIR = liveMedia
GROUPSOCK_DIR = groupsock
USAGE_ENVIRONMENT_DIR = UsageEnvironment
BASIC_USAGE_ENVIRONMENT_DIR = BasicUsageEnvironment

all:
	cd $(LIVEMEDIA_DIR) ; $(MAKE)
	cd $(GROUPSOCK_DIR) ; $(MAKE)
	cd $(USAGE_ENVIRONMENT_DIR) ; $(MAKE)
	cd $(BASIC_USAGE_ENVIRONMENT_DIR) ; $(MAKE)
	@echo
	@echo "For more information about this source code (including your obligations under the LGPL), please see our FAQ at http://live555.com/liveMedia/faq.html"

install:
	cd $(LIVEMEDIA_DIR) ; $(MAKE) install
	cd $(GROUPSOCK_DIR) ; $(MAKE) install
	cd $(USAGE_ENVIRONMENT_DIR) ; $(MAKE) install
	cd $(BASIC_USAGE_ENVIRONMENT_DIR) ; $(MAKE) install

clean:
	cd $(LIVEMEDIA_DIR) ; $(MAKE) clean
	cd $(GROUPSOCK_DIR) ; $(MAKE) clean
	cd $(USAGE_ENVIRONMENT_DIR) ; $(MAKE) clean
	cd $(BASIC_USAGE_ENVIRONMENT_DIR) ; $(MAKE) clean

distclean: clean
	-rm -f $(LIVEMEDIA_DIR)/Makefile $(GROUPSOCK_DIR)/Makefile \
	  $(USAGE_ENVIRONMENT_DIR)/Makefile $(BASIC_USAGE_ENVIRONMENT_DIR)/Makefile \ 
	  Makefile
