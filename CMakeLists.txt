cmake_minimum_required(VERSION 3.20.0)

project(minikin VERSION 0.1.0)
set(PROJ_NAME minikin)

file(GLOB SOURCES "libs/minikin/*.cpp")
add_library(${PROJ_NAME} ${SOURCES})

# 未定義実装を置き換えるための強制インクルードヘッダを指定する
set(STUB_FILE "${PROJECT_SOURCE_DIR}/libs/_stub.h")

if(MSVC)
  set(MSVC_GLOBAL_OPTIONS /utf-8 /wd4819 /wd4996 /wd4244 /wd4018 /MP)
  target_compile_options(${PROJ_NAME} PRIVATE /FI${STUB_FILE} ${MSVC_GLOBAL_OPTIONS})
  # harfbuzz-icu-freetype のビルドでコケるのでグローバルにUTF8オプション付与
  # ついでに並列ビルドと各種Warn抑制(コードページ、unsigned比較等)
  add_compile_options(${MSVC_GLOBAL_OPTIONS})
else()
  # GCC or Clang
  target_compile_options(${PROJ_NAME} PRIVATE -include ${STUB_FILE})
endif()

# インクルードパス
# libs/ は本来内部実装用の非公開パスだが全部見えるようにしておく(テスト向け)
target_include_directories(${PROJ_NAME} PUBLIC include libs)

# Wamsoft の変更部分を有効にする
add_compile_definitions(WAMSOFT_MODIFIED)

# ==============================================================================
# 外部ライブラリ設定
# ==============================================================================

# FreeType は vcpkg からインストール
find_package(freetype CONFIG REQUIRED)

# ICU 78.2 (GitHub からソース取得してビルド)
add_subdirectory(${PROJECT_SOURCE_DIR}/ext/icu)

# HarfBuzz 13.1.1 (GitHub から取得、freetype と ICU に依存)
add_subdirectory(${PROJECT_SOURCE_DIR}/ext/harfbuzz)

# ICU データライブラリ (build/icudata で事前ビルド済み)
set(ICU_DATA_LIB ${PROJECT_SOURCE_DIR}/build/icudata/lib/libicudt78.a)

# ==============================================================================
# リンク設定
# ==============================================================================
target_link_libraries(${PROJ_NAME} PUBLIC 
  freetype
  icucommon 
  harfbuzz 
  ${ICU_DATA_LIB}
)
