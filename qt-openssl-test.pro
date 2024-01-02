# =============================================================================
# Parts of Qt
# =============================================================================

QT += network
QT += widgets  # required to #include <QApplication>

# =============================================================================
# Overall configuration
# =============================================================================

CONFIG += mobility
CONFIG += c++11

DEFINES += QT_DEPRECATED_WARNINGS


# =============================================================================
# Compiler and linker flags
# =============================================================================

gcc | clang {
    COMPILER_VERSION = $$system($$QMAKE_CXX " -dumpversion")
    COMPILER_MAJOR_VERSION = $$str_member($$COMPILER_VERSION)
}

gcc {
    QMAKE_CXXFLAGS += -Werror  # warnings become errors
}

if (gcc | clang):!ios:!android!macx {
    !lessThan(COMPILER_MAJOR_VERSION, 9) {
        QMAKE_CXXFLAGS += -Wno-deprecated-copy
    }
}

if (ios | macx)  {
    QMAKE_CFLAGS_WARN_ON += -Wno-deprecated-copy
    QMAKE_CXXFLAGS_WARN_ON += -Wno-deprecated-copy
}

gcc {
    QMAKE_CXXFLAGS += -fvisibility=hidden
}

# =============================================================================
# Build targets
# =============================================================================

TARGET = qt-openssl-test
TEMPLATE = app

# -----------------------------------------------------------------------------
# Architecture
# -----------------------------------------------------------------------------

linux : {
    CONFIG += static
}

# =============================================================================
# Source files
# =============================================================================

SOURCES += \
    main.cpp

linux : !android {
    # -------------------------------------------------------------------------
    # LINUX -- and not Android Linux!
    # -------------------------------------------------------------------------
    STATIC_LIB_EXT = ".a"
    DYNAMIC_LIB_EXT = ".so"
    QT_LINKAGE = "static"
    OPENSSL_LINKAGE = "static"

    # https://stackoverflow.com/questions/33117822
    # https://stackoverflow.com/questions/356666
    contains(QT_ARCH, x86_64) {
        message("Building for Linux/x86_64")
        ARCH_TAG = "linux_x86_64"
    } else {  # will be "i386"
        message("Building for Linux/x86_32")
        ARCH_TAG = "linux_x86_32"
    }
}
android {
    # -------------------------------------------------------------------------
    # ANDROID
    # -------------------------------------------------------------------------
    STATIC_LIB_EXT = ".a"
    DYNAMIC_LIB_EXT = ".so"
    QT_LINKAGE = "dynamic"
    # OPENSSL_LINKAGE = "static"
    OPENSSL_LINKAGE = "dynamic"

    contains(ANDROID_TARGET_ARCH, x86) {
        message("Building for Android/x86 (e.g. Android emulator)")
        ARCH_TAG = "android_x86"
    }
    contains(ANDROID_TARGET_ARCH, armeabi-v7a) {
        message("Building for Android/ARMv7 32-bit architecture")
        ARCH_TAG = "android_armv7"
    }
    contains(ANDROID_TARGET_ARCH, arm64-v8a) {
        message("Building for Android/ARMv8 64-bit architecture")
        ARCH_TAG = "android_armv8_64"
    }

    message("Environment variable ANDROID_NDK_ROOT (should be set by Qt Creator): $$(ANDROID_NDK_ROOT)")
    # ... https://bugreports.qt.io/browse/QTCREATORBUG-15240
}
windows {
    # -------------------------------------------------------------------------
    # WINDOWS
    # -------------------------------------------------------------------------
    STATIC_LIB_EXT = ".lib"
    DYNAMIC_LIB_EXT = ".dll"
    OBJ_EXT = ".obj"
    QT_LINKAGE = "static"
    OPENSSL_LINKAGE = "static"

    # https://stackoverflow.com/questions/26373143
    # https://stackoverflow.com/questions/33117822
    # https://stackoverflow.com/questions/356666
    contains(QT_ARCH, x86_64) {
        message("Building for Windows/x86_64 architecture")
        ARCH_TAG = "windows_x86_64"
    } else {
        message("Building for Windows/x86_32 architecture")
        ARCH_TAG = "windows_x86_32"
    }

}
macx {
    # -------------------------------------------------------------------------
    # MacOS (formerly OS X)
    # -------------------------------------------------------------------------
    STATIC_LIB_EXT = ".a"
    DYNAMIC_LIB_EXT = ".dylib"
    QT_LINKAGE = "static"
    OPENSSL_LINKAGE = "static"

    contains(QT_ARCH, x86_64) {
        message("Building for MacOS/x86_64 architecture")
        ARCH_TAG = "macos_x86_64"
    } else {
        message("Building for MacOS/x86_32 architecture")
        ARCH_TAG = "macos_x86_32"
    }
}
ios {
    # -------------------------------------------------------------------------
    # iOS
    # -------------------------------------------------------------------------
    STATIC_LIB_EXT = ".a"
    DYNAMIC_LIB_EXT = ".dylib"
    QT_LINKAGE = "static"
    OPENSSL_LINKAGE = "static"

    # Both iphoneos and iphonesimulator are set ?!
    CONFIG(iphoneos, iphoneos|iphonesimulator) {
        message("Building for iPhone OS")
        contains(QT_ARCH, arm64) {
            message("Building for iOS/ARM v8 64-bit architecture")
            ARCH_TAG = "ios_armv8_64"
        } else {
            message("Building for iOS/ARM v7 (32-bit) architecture")
            ARCH_TAG = "ios_armv7"
        }
    }

    CONFIG(iphonesimulator, iphoneos|iphonesimulator) {
        message("Building for iPhone Simulator")
        ARCH_TAG = "ios_x86_64"
    }

    disable_warning.name = "GCC_WARN_64_TO_32_BIT_CONVERSION"
    disable_warning.value = "No"
    QMAKE_MAC_XCODE_SETTINGS += disable_warning

}

isEmpty(ARCH_TAG) {
    error("Unknown architecture")
}


OPENSSL_VERSION = "3.0.12"
QT_BASE_DIR = "/home/martinb/workspace/qt6_local_build"  # value at time of qmake ("now")
OPENSSL_SUBDIR = openssl-$${OPENSSL_VERSION}
OPENSSL_DIR = "$${QT_BASE_DIR}/openssl_$${ARCH_TAG}_build/$${OPENSSL_SUBDIR}"
message("Using OpenSSL version $$OPENSSL_VERSION from $${OPENSSL_DIR}")
INCLUDEPATH += "$${OPENSSL_DIR}/include"
equals(OPENSSL_LINKAGE, "static") {
    LIBS += "-L$${OPENSSL_DIR}"  # path; shouldn't be necessary for static linkage! Residual problem.
    LIBS += "$${OPENSSL_DIR}/libcrypto$${STATIC_LIB_EXT}"  # raw filename, not -l
    LIBS += "$${OPENSSL_DIR}/libssl$${STATIC_LIB_EXT}"  # raw filename, not -l
} else {
    LIBS += "-L$${OPENSSL_DIR}"  # path
    LIBS += "-lcrypto"
    LIBS += "-lssl"
}

ANDROID_EXTRA_LIBS += "$${OPENSSL_DIR}/libcrypto_3$${DYNAMIC_LIB_EXT}"  # needed for Qt
ANDROID_EXTRA_LIBS += "$${OPENSSL_DIR}/libssl_3$${DYNAMIC_LIB_EXT}"
android {
    message("ANDROID_EXTRA_LIBS=$${ANDROID_EXTRA_LIBS}")
}
