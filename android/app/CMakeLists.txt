cmake_minimum_required(VERSION 3.4.1)

set(C_STANDARD 11)

add_library(greenaddress-lib SHARED IMPORTED)
set_target_properties(greenaddress-lib PROPERTIES IMPORTED_LOCATION
    "${CMAKE_CURRENT_SOURCE_DIR}/../../crypto/gdk-android-jni/lib/${ANDROID_ABI}/libgreenaddress.so")

add_library(dart_helper SHARED
    ../../ffi/dart_helper/callbacks.c
)

target_include_directories(dart_helper PRIVATE ../../crypto/gdk-android-jni/include)

target_link_libraries(dart_helper greenaddress-lib)
