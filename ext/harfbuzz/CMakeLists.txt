cmake_minimum_required(VERSION 3.20.0)

project(harfbuzz VERSION 13.1.1 LANGUAGES CXX C)

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
# FetchContent_Populate を使用してソースのみを取得（CMakeLists.txt を実行しない）
FetchContent_GetProperties(harfbuzz_source)
if(NOT harfbuzz_source_POPULATED)
    FetchContent_Populate(harfbuzz_source)
endif()

set(HB_SOURCE_DIR "${harfbuzz_source_SOURCE_DIR}/src")

# HarfBuzz ソースファイル
set(HB_SOURCES
    ${HB_SOURCE_DIR}/hb-aat-layout.cc
    ${HB_SOURCE_DIR}/hb-aat-map.cc
    ${HB_SOURCE_DIR}/hb-blob.cc
    ${HB_SOURCE_DIR}/hb-buffer-serialize.cc
    ${HB_SOURCE_DIR}/hb-buffer-verify.cc
    ${HB_SOURCE_DIR}/hb-buffer.cc
    ${HB_SOURCE_DIR}/hb-common.cc
    ${HB_SOURCE_DIR}/hb-draw.cc
    ${HB_SOURCE_DIR}/hb-face.cc
    ${HB_SOURCE_DIR}/hb-face-builder.cc
    ${HB_SOURCE_DIR}/hb-fallback-shape.cc
    ${HB_SOURCE_DIR}/hb-font.cc
    ${HB_SOURCE_DIR}/hb-map.cc
    ${HB_SOURCE_DIR}/hb-number.cc
    ${HB_SOURCE_DIR}/hb-ot-cff1-table.cc
    ${HB_SOURCE_DIR}/hb-ot-cff2-table.cc
    ${HB_SOURCE_DIR}/hb-ot-color.cc
    ${HB_SOURCE_DIR}/hb-ot-face.cc
    ${HB_SOURCE_DIR}/hb-ot-font.cc
    ${HB_SOURCE_DIR}/hb-ot-layout.cc
    ${HB_SOURCE_DIR}/hb-ot-map.cc
    ${HB_SOURCE_DIR}/hb-ot-math.cc
    ${HB_SOURCE_DIR}/hb-ot-meta.cc
    ${HB_SOURCE_DIR}/hb-ot-metrics.cc
    ${HB_SOURCE_DIR}/hb-ot-name.cc
    ${HB_SOURCE_DIR}/hb-ot-shaper-arabic.cc
    ${HB_SOURCE_DIR}/hb-ot-shaper-default.cc
    ${HB_SOURCE_DIR}/hb-ot-shaper-hangul.cc
    ${HB_SOURCE_DIR}/hb-ot-shaper-hebrew.cc
    ${HB_SOURCE_DIR}/hb-ot-shaper-indic-table.cc
    ${HB_SOURCE_DIR}/hb-ot-shaper-indic.cc
    ${HB_SOURCE_DIR}/hb-ot-shaper-khmer.cc
    ${HB_SOURCE_DIR}/hb-ot-shaper-myanmar.cc
    ${HB_SOURCE_DIR}/hb-ot-shaper-syllabic.cc
    ${HB_SOURCE_DIR}/hb-ot-shaper-thai.cc
    ${HB_SOURCE_DIR}/hb-ot-shaper-use.cc
    ${HB_SOURCE_DIR}/hb-ot-shaper-vowel-constraints.cc
    ${HB_SOURCE_DIR}/hb-ot-shape-fallback.cc
    ${HB_SOURCE_DIR}/hb-ot-shape-normalize.cc
    ${HB_SOURCE_DIR}/hb-ot-shape.cc
    ${HB_SOURCE_DIR}/hb-ot-tag.cc
    ${HB_SOURCE_DIR}/hb-ot-var.cc
    ${HB_SOURCE_DIR}/hb-outline.cc
    ${HB_SOURCE_DIR}/hb-paint.cc
    ${HB_SOURCE_DIR}/hb-paint-extents.cc
    ${HB_SOURCE_DIR}/hb-set.cc
    ${HB_SOURCE_DIR}/hb-shape-plan.cc
    ${HB_SOURCE_DIR}/hb-shape.cc
    ${HB_SOURCE_DIR}/hb-shaper.cc
    ${HB_SOURCE_DIR}/hb-static.cc
    ${HB_SOURCE_DIR}/hb-style.cc
    ${HB_SOURCE_DIR}/hb-ucd.cc
    ${HB_SOURCE_DIR}/hb-unicode.cc
    # FreeType integration
    ${HB_SOURCE_DIR}/hb-ft.cc
)

# オプション
option(HB_HAVE_ICU "Enable ICU integration" ON)
option(HB_HAVE_FREETYPE "Enable FreeType integration" ON)

# HarfBuzz ライブラリ作成
add_library(harfbuzz STATIC ${HB_SOURCES})

target_include_directories(harfbuzz PUBLIC
    ${HB_SOURCE_DIR}
)

target_compile_definitions(harfbuzz PRIVATE
    HAVE_OT              # OT shaper を含める
    HB_NO_MT             # マルチスレッドサポートを除外
)

# FreeType 統合
if(HB_HAVE_FREETYPE)
    find_package(freetype CONFIG REQUIRED)
    target_link_libraries(harfbuzz PUBLIC freetype)
    target_compile_definitions(harfbuzz PRIVATE HAVE_FREETYPE)
endif()

# ICU 統合
if(HB_HAVE_ICU)
    target_sources(harfbuzz PRIVATE ${HB_SOURCE_DIR}/hb-icu.cc)
    target_link_libraries(harfbuzz PRIVATE icucommon)
    target_compile_definitions(harfbuzz PRIVATE HAVE_ICU HAVE_ICU_BUILTIN)
endif()

# CoreText 統合 (macOS)
if(APPLE)
    option(HB_HAVE_CORETEXT "Enable CoreText shaper backend on macOS" ON)
    if(HB_HAVE_CORETEXT)
        target_compile_definitions(harfbuzz PRIVATE HAVE_CORETEXT)
        target_sources(harfbuzz PRIVATE ${HB_SOURCE_DIR}/hb-coretext.cc)
        if(IOS)
            target_link_libraries(harfbuzz PRIVATE
                "-framework CoreText"
                "-framework CoreGraphics"
            )
        else()
            target_link_libraries(harfbuzz PRIVATE
                "-framework ApplicationServices"
            )
        endif()
    endif()
endif()

# コンパイラオプション
if(MSVC)
    target_compile_options(harfbuzz PRIVATE
        /utf-8
        /wd4996
        /wd4267
        /wd4244
    )
else()
    # GCC/Clang
    target_compile_options(harfbuzz PRIVATE
        -fno-rtti
        -fno-exceptions
        -fno-threadsafe-statics
    )
endif()

# エイリアスターゲット
add_library(HarfBuzz::HarfBuzz ALIAS harfbuzz)
