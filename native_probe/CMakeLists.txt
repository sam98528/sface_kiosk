cmake_minimum_required(VERSION 3.16)
project(native_probe CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_executable(native_probe
  main.cpp
  edsdk_bridge.cpp
)

# edsdk_bridge에서 Windows/COM/WIC 사용
target_link_libraries(native_probe PRIVATE ole32 windowscodecs)
# EDSDK 경로
set(EDSDK_ROOT    "${CMAKE_CURRENT_SOURCE_DIR}/windows/third_party/edsdk")
set(EDSDK_BIN_DIR "${EDSDK_ROOT}/bin/x64")
set(EDSDK_LIB_DIR "${EDSDK_ROOT}/lib/x64")

# (선택) .lib 링크
if(EXISTS "${EDSDK_LIB_DIR}/EDSDK.lib")
  target_link_libraries(native_probe PRIVATE "${EDSDK_LIB_DIR}/EDSDK.lib")
endif()

# 🔴 DLL 존재 여부를 사전 체크해서 명확한 에러를 주자
if(NOT EXISTS "${EDSDK_BIN_DIR}/EDSDK.dll")
  message(FATAL_ERROR "EDSDK.dll not found at: ${EDSDK_BIN_DIR}/EDSDK.dll")
endif()
if(NOT EXISTS "${EDSDK_BIN_DIR}/EdsImage.dll")
  message(FATAL_ERROR "EdsImage.dll not found at: ${EDSDK_BIN_DIR}/EdsImage.dll")
endif()

# 🔵 빌드 후 DLL 자동 복사 (경로는 반드시 따옴표!)
add_custom_command(TARGET native_probe POST_BUILD
  COMMAND "${CMAKE_COMMAND}" -E copy_if_different
          "${EDSDK_BIN_DIR}/EDSDK.dll"     "$<TARGET_FILE_DIR:native_probe>"
  COMMAND "${CMAKE_COMMAND}" -E copy_if_different
          "${EDSDK_BIN_DIR}/EdsImage.dll"  "$<TARGET_FILE_DIR:native_probe>"
)