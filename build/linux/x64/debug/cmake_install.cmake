# Install script for directory: /home/saisreenath/Desktop/Projects/cuBRm/linux

# Set the install prefix
if(NOT DEFINED CMAKE_INSTALL_PREFIX)
  set(CMAKE_INSTALL_PREFIX "/home/saisreenath/Desktop/Projects/cuBRm/build/linux/x64/debug/bundle")
endif()
string(REGEX REPLACE "/$" "" CMAKE_INSTALL_PREFIX "${CMAKE_INSTALL_PREFIX}")

# Set the install configuration name.
if(NOT DEFINED CMAKE_INSTALL_CONFIG_NAME)
  if(BUILD_TYPE)
    string(REGEX REPLACE "^[^A-Za-z0-9_]+" ""
           CMAKE_INSTALL_CONFIG_NAME "${BUILD_TYPE}")
  else()
    set(CMAKE_INSTALL_CONFIG_NAME "Debug")
  endif()
  message(STATUS "Install configuration: \"${CMAKE_INSTALL_CONFIG_NAME}\"")
endif()

# Set the component getting installed.
if(NOT CMAKE_INSTALL_COMPONENT)
  if(COMPONENT)
    message(STATUS "Install component: \"${COMPONENT}\"")
    set(CMAKE_INSTALL_COMPONENT "${COMPONENT}")
  else()
    set(CMAKE_INSTALL_COMPONENT)
  endif()
endif()

# Install shared libraries without execute permission?
if(NOT DEFINED CMAKE_INSTALL_SO_NO_EXE)
  set(CMAKE_INSTALL_SO_NO_EXE "0")
endif()

# Is this installation the result of a crosscompile?
if(NOT DEFINED CMAKE_CROSSCOMPILING)
  set(CMAKE_CROSSCOMPILING "FALSE")
endif()

# Set path to fallback-tool for dependency-resolution.
if(NOT DEFINED CMAKE_OBJDUMP)
  set(CMAKE_OBJDUMP "/usr/bin/llvm-objdump")
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Runtime" OR NOT CMAKE_INSTALL_COMPONENT)
  
  file(REMOVE_RECURSE "/home/saisreenath/Desktop/Projects/cuBRm/build/linux/x64/debug/bundle/")
  
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Runtime" OR NOT CMAKE_INSTALL_COMPONENT)
  if(EXISTS "$ENV{DESTDIR}/home/saisreenath/Desktop/Projects/cuBRm/build/linux/x64/debug/bundle/mocha" AND
     NOT IS_SYMLINK "$ENV{DESTDIR}/home/saisreenath/Desktop/Projects/cuBRm/build/linux/x64/debug/bundle/mocha")
    file(RPATH_CHECK
         FILE "$ENV{DESTDIR}/home/saisreenath/Desktop/Projects/cuBRm/build/linux/x64/debug/bundle/mocha"
         RPATH "$ORIGIN/lib")
  endif()
  list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
   "/home/saisreenath/Desktop/Projects/cuBRm/build/linux/x64/debug/bundle/mocha")
  if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  file(INSTALL DESTINATION "/home/saisreenath/Desktop/Projects/cuBRm/build/linux/x64/debug/bundle" TYPE EXECUTABLE FILES "/home/saisreenath/Desktop/Projects/cuBRm/build/linux/x64/debug/intermediates_do_not_run/mocha")
  if(EXISTS "$ENV{DESTDIR}/home/saisreenath/Desktop/Projects/cuBRm/build/linux/x64/debug/bundle/mocha" AND
     NOT IS_SYMLINK "$ENV{DESTDIR}/home/saisreenath/Desktop/Projects/cuBRm/build/linux/x64/debug/bundle/mocha")
    file(RPATH_CHANGE
         FILE "$ENV{DESTDIR}/home/saisreenath/Desktop/Projects/cuBRm/build/linux/x64/debug/bundle/mocha"
         OLD_RPATH "/home/saisreenath/Desktop/Projects/cuBRm/build/linux/x64/debug/plugins/desktop_drop:/home/saisreenath/Desktop/Projects/cuBRm/build/linux/x64/debug/plugins/screen_retriever:/home/saisreenath/Desktop/Projects/cuBRm/build/linux/x64/debug/plugins/sqlite3_flutter_libs:/home/saisreenath/Desktop/Projects/cuBRm/build/linux/x64/debug/plugins/tray_manager:/home/saisreenath/Desktop/Projects/cuBRm/build/linux/x64/debug/plugins/window_manager:/home/saisreenath/Desktop/Projects/cuBRm/linux/flutter/ephemeral:"
         NEW_RPATH "$ORIGIN/lib")
    if(CMAKE_INSTALL_DO_STRIP)
      execute_process(COMMAND "/usr/bin/llvm-strip" "$ENV{DESTDIR}/home/saisreenath/Desktop/Projects/cuBRm/build/linux/x64/debug/bundle/mocha")
    endif()
  endif()
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Runtime" OR NOT CMAKE_INSTALL_COMPONENT)
  list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
   "/home/saisreenath/Desktop/Projects/cuBRm/build/linux/x64/debug/bundle/data/icudtl.dat")
  if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  file(INSTALL DESTINATION "/home/saisreenath/Desktop/Projects/cuBRm/build/linux/x64/debug/bundle/data" TYPE FILE FILES "/home/saisreenath/Desktop/Projects/cuBRm/linux/flutter/ephemeral/icudtl.dat")
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Runtime" OR NOT CMAKE_INSTALL_COMPONENT)
  list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
   "/home/saisreenath/Desktop/Projects/cuBRm/build/linux/x64/debug/bundle/lib/libflutter_linux_gtk.so")
  if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  file(INSTALL DESTINATION "/home/saisreenath/Desktop/Projects/cuBRm/build/linux/x64/debug/bundle/lib" TYPE FILE FILES "/home/saisreenath/Desktop/Projects/cuBRm/linux/flutter/ephemeral/libflutter_linux_gtk.so")
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Runtime" OR NOT CMAKE_INSTALL_COMPONENT)
  list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
   "/home/saisreenath/Desktop/Projects/cuBRm/build/linux/x64/debug/bundle/lib/libdesktop_drop_plugin.so")
  if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  file(INSTALL DESTINATION "/home/saisreenath/Desktop/Projects/cuBRm/build/linux/x64/debug/bundle/lib" TYPE FILE FILES "/home/saisreenath/Desktop/Projects/cuBRm/build/linux/x64/debug/plugins/desktop_drop/libdesktop_drop_plugin.so")
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Runtime" OR NOT CMAKE_INSTALL_COMPONENT)
  list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
   "/home/saisreenath/Desktop/Projects/cuBRm/build/linux/x64/debug/bundle/lib/libscreen_retriever_plugin.so")
  if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  file(INSTALL DESTINATION "/home/saisreenath/Desktop/Projects/cuBRm/build/linux/x64/debug/bundle/lib" TYPE FILE FILES "/home/saisreenath/Desktop/Projects/cuBRm/build/linux/x64/debug/plugins/screen_retriever/libscreen_retriever_plugin.so")
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Runtime" OR NOT CMAKE_INSTALL_COMPONENT)
  list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
   "/home/saisreenath/Desktop/Projects/cuBRm/build/linux/x64/debug/bundle/lib/libsqlite3_flutter_libs_plugin.so")
  if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  file(INSTALL DESTINATION "/home/saisreenath/Desktop/Projects/cuBRm/build/linux/x64/debug/bundle/lib" TYPE FILE FILES "/home/saisreenath/Desktop/Projects/cuBRm/build/linux/x64/debug/plugins/sqlite3_flutter_libs/libsqlite3_flutter_libs_plugin.so")
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Runtime" OR NOT CMAKE_INSTALL_COMPONENT)
  list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
   "/home/saisreenath/Desktop/Projects/cuBRm/build/linux/x64/debug/bundle/lib/libtray_manager_plugin.so")
  if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  file(INSTALL DESTINATION "/home/saisreenath/Desktop/Projects/cuBRm/build/linux/x64/debug/bundle/lib" TYPE FILE FILES "/home/saisreenath/Desktop/Projects/cuBRm/build/linux/x64/debug/plugins/tray_manager/libtray_manager_plugin.so")
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Runtime" OR NOT CMAKE_INSTALL_COMPONENT)
  list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
   "/home/saisreenath/Desktop/Projects/cuBRm/build/linux/x64/debug/bundle/lib/libwindow_manager_plugin.so")
  if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  file(INSTALL DESTINATION "/home/saisreenath/Desktop/Projects/cuBRm/build/linux/x64/debug/bundle/lib" TYPE FILE FILES "/home/saisreenath/Desktop/Projects/cuBRm/build/linux/x64/debug/plugins/window_manager/libwindow_manager_plugin.so")
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Runtime" OR NOT CMAKE_INSTALL_COMPONENT)
  list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
   "/home/saisreenath/Desktop/Projects/cuBRm/build/linux/x64/debug/bundle/lib/libflutter_soloud_plugin.so")
  if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  file(INSTALL DESTINATION "/home/saisreenath/Desktop/Projects/cuBRm/build/linux/x64/debug/bundle/lib" TYPE FILE FILES "/home/saisreenath/Desktop/Projects/cuBRm/build/linux/x64/debug/plugins/flutter_soloud/libflutter_soloud_plugin.so")
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Runtime" OR NOT CMAKE_INSTALL_COMPONENT)
  list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
   "/home/saisreenath/Desktop/Projects/cuBRm/build/linux/x64/debug/bundle/lib/libdartjni.so")
  if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  file(INSTALL DESTINATION "/home/saisreenath/Desktop/Projects/cuBRm/build/linux/x64/debug/bundle/lib" TYPE FILE FILES "/home/saisreenath/Desktop/Projects/cuBRm/build/linux/x64/debug/plugins/jni/shared/libdartjni.so")
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Runtime" OR NOT CMAKE_INSTALL_COMPONENT)
  list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
   "/home/saisreenath/Desktop/Projects/cuBRm/build/linux/x64/debug/bundle/lib/")
  if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  file(INSTALL DESTINATION "/home/saisreenath/Desktop/Projects/cuBRm/build/linux/x64/debug/bundle/lib" TYPE DIRECTORY FILES "/home/saisreenath/Desktop/Projects/cuBRm/build/native_assets/linux/")
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Runtime" OR NOT CMAKE_INSTALL_COMPONENT)
  
  file(REMOVE_RECURSE "/home/saisreenath/Desktop/Projects/cuBRm/build/linux/x64/debug/bundle/data/flutter_assets")
  
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Runtime" OR NOT CMAKE_INSTALL_COMPONENT)
  list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
   "/home/saisreenath/Desktop/Projects/cuBRm/build/linux/x64/debug/bundle/data/flutter_assets")
  if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  file(INSTALL DESTINATION "/home/saisreenath/Desktop/Projects/cuBRm/build/linux/x64/debug/bundle/data" TYPE DIRECTORY FILES "/home/saisreenath/Desktop/Projects/cuBRm/build//flutter_assets")
endif()

if(NOT CMAKE_INSTALL_LOCAL_ONLY)
  # Include the install script for each subdirectory.
  include("/home/saisreenath/Desktop/Projects/cuBRm/build/linux/x64/debug/flutter/cmake_install.cmake")
  include("/home/saisreenath/Desktop/Projects/cuBRm/build/linux/x64/debug/runner/cmake_install.cmake")
  include("/home/saisreenath/Desktop/Projects/cuBRm/build/linux/x64/debug/plugins/desktop_drop/cmake_install.cmake")
  include("/home/saisreenath/Desktop/Projects/cuBRm/build/linux/x64/debug/plugins/screen_retriever/cmake_install.cmake")
  include("/home/saisreenath/Desktop/Projects/cuBRm/build/linux/x64/debug/plugins/sqlite3_flutter_libs/cmake_install.cmake")
  include("/home/saisreenath/Desktop/Projects/cuBRm/build/linux/x64/debug/plugins/tray_manager/cmake_install.cmake")
  include("/home/saisreenath/Desktop/Projects/cuBRm/build/linux/x64/debug/plugins/window_manager/cmake_install.cmake")
  include("/home/saisreenath/Desktop/Projects/cuBRm/build/linux/x64/debug/plugins/flutter_soloud/cmake_install.cmake")
  include("/home/saisreenath/Desktop/Projects/cuBRm/build/linux/x64/debug/plugins/jni/cmake_install.cmake")

endif()

string(REPLACE ";" "\n" CMAKE_INSTALL_MANIFEST_CONTENT
       "${CMAKE_INSTALL_MANIFEST_FILES}")
if(CMAKE_INSTALL_LOCAL_ONLY)
  file(WRITE "/home/saisreenath/Desktop/Projects/cuBRm/build/linux/x64/debug/install_local_manifest.txt"
     "${CMAKE_INSTALL_MANIFEST_CONTENT}")
endif()
if(CMAKE_INSTALL_COMPONENT)
  if(CMAKE_INSTALL_COMPONENT MATCHES "^[a-zA-Z0-9_.+-]+$")
    set(CMAKE_INSTALL_MANIFEST "install_manifest_${CMAKE_INSTALL_COMPONENT}.txt")
  else()
    string(MD5 CMAKE_INST_COMP_HASH "${CMAKE_INSTALL_COMPONENT}")
    set(CMAKE_INSTALL_MANIFEST "install_manifest_${CMAKE_INST_COMP_HASH}.txt")
    unset(CMAKE_INST_COMP_HASH)
  endif()
else()
  set(CMAKE_INSTALL_MANIFEST "install_manifest.txt")
endif()

if(NOT CMAKE_INSTALL_LOCAL_ONLY)
  file(WRITE "/home/saisreenath/Desktop/Projects/cuBRm/build/linux/x64/debug/${CMAKE_INSTALL_MANIFEST}"
     "${CMAKE_INSTALL_MANIFEST_CONTENT}")
endif()
