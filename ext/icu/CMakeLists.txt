cmake_minimum_required(VERSION 3.20.0)

project(icucommon VERSION 78.2 LANGUAGES CXX C)

# ICU 78.2 をダウンロード（GitHubソースコードアーカイブを使用）
include(FetchContent)
set(ICU_VERSION "release-78.2")
set(ICU_URL "https://github.com/unicode-org/icu/archive/refs/tags/${ICU_VERSION}.tar.gz")

FetchContent_Declare(
    icu_source
    URL ${ICU_URL}
    DOWNLOAD_EXTRACT_TIMESTAMP TRUE
)

message(STATUS "Downloading ICU 78.2 from ${ICU_URL}...")
FetchContent_MakeAvailable(icu_source)

# GitHubアーカイブの構造: icu-release-78.2/icu4c/source/
set(ICU_SOURCE_DIR "${icu_source_SOURCE_DIR}/icu4c/source")

# common ディレクトリのソースを収集
file(GLOB ICU_COMMON_SOURCES "${ICU_SOURCE_DIR}/common/*.cpp")
file(GLOB ICU_COMMON_C_SOURCES "${ICU_SOURCE_DIR}/common/*.c")

# stubdata ソース
set(ICU_STUBDATA_SOURCES "${ICU_SOURCE_DIR}/stubdata/stubdata.cpp")

# icucommon ライブラリ作成
add_library(icucommon STATIC
    ${ICU_COMMON_SOURCES}
    ${ICU_COMMON_C_SOURCES}
    ${ICU_STUBDATA_SOURCES}
)

target_include_directories(icucommon PUBLIC
    ${ICU_SOURCE_DIR}/common
    ${ICU_SOURCE_DIR}/stubdata
)

target_compile_definitions(icucommon PUBLIC
    U_STATIC_IMPLEMENTATION=1
    PIC
    U_COMMON_IMPLEMENTATION
)

# MSVC 設定
if(MSVC)
    target_compile_options(icucommon PRIVATE
        /Zc:__cplusplus  # __cplusplus マクロを正しく設定
        /utf-8           # UTF-8 ソースファイル
        /wd4267          # size_t -> int 変換警告
        /wd4244          # 暗黙の型変換警告
        /wd4996          # deprecated 警告
        /std:c++17       # この指定がないとダメっぽい
    )
endif()

# エイリアスターゲット
add_library(ICU::common ALIAS icucommon)

# ==============================================================================
# HarfBuzz の find_package(ICU) をバイパスするための設定
# ==============================================================================

# ICU::uc エイリアス (HarfBuzz は ICU::uc を要求する)
add_library(ICU::uc ALIAS icucommon)

# ICU バージョン情報をエクスポート（親スコープにも設定）
set(ICU_VERSION "78.2" CACHE STRING "ICU version" FORCE)
set(ICU_FOUND TRUE CACHE BOOL "ICU found" FORCE)
set(ICU_uc_FOUND TRUE CACHE BOOL "ICU uc component found" FORCE)

# インクルードディレクトリをエクスポート
set(ICU_INCLUDE_DIRS "${ICU_SOURCE_DIR}/common" CACHE PATH "ICU include directories" FORCE)
