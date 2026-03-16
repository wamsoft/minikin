cmake_minimum_required(VERSION 3.20.0)

# ==============================================================================
# HarfBuzz 13.1.1 ビルド設定
# ==============================================================================
# オリジナルの HarfBuzz CMakeLists.txt を使用
# ICU は ext/icu で事前にビルドされた ICU::uc ターゲットを使用

# HarfBuzz ビルドオプションを事前に設定
set(HB_HAVE_FREETYPE ON CACHE BOOL "Enable freetype interop helpers" FORCE)
set(HB_HAVE_ICU ON CACHE BOOL "Enable icu unicode functions" FORCE)
set(HB_BUILD_SUBSET OFF CACHE BOOL "Build harfbuzz-subset" FORCE)
set(HB_BUILD_UTILS OFF CACHE BOOL "Build harfbuzz utils" FORCE)
set(HB_BUILD_RASTER OFF CACHE BOOL "Build harfbuzz-raster" FORCE)
set(HB_BUILD_VECTOR OFF CACHE BOOL "Build harfbuzz-vector" FORCE)

# インストールをスキップ（icucommon がエクスポートセットに含まれないため）
set(SKIP_INSTALL_ALL ON CACHE BOOL "Skip all install targets" FORCE)
set(SKIP_INSTALL_LIBRARIES ON CACHE BOOL "Skip library install" FORCE)
set(SKIP_INSTALL_HEADERS ON CACHE BOOL "Skip header install" FORCE)

# カスタム FindICU.cmake を使用するためのモジュールパス設定
list(INSERT CMAKE_MODULE_PATH 0 "${CMAKE_CURRENT_SOURCE_DIR}")

# HarfBuzz 13.1.1 をダウンロード
include(FetchContent)
set(HB_VERSION "13.1.1")

FetchContent_Declare(
    harfbuzz_source
    GIT_REPOSITORY https://github.com/harfbuzz/harfbuzz.git
    GIT_TAG ${HB_VERSION}
    GIT_SHALLOW TRUE
)

message(STATUS "Downloading HarfBuzz ${HB_VERSION}...")
# FetchContent_MakeAvailable を使用してオリジナルの CMakeLists.txt を実行
FetchContent_MakeAvailable(harfbuzz_source)
add_library(HarfBuzz::HarfBuzz ALIAS harfbuzz)
