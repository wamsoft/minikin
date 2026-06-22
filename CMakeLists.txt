cmake_minimum_required(VERSION 3.20.0)

set(ICU_VERSION "77.1" CACHE STRING "ICU version (major version only, e.g. 77)")
set(ICU_VERSION_TAG "77-1" CACHE STRING "ICU version tag (e.g. 77-1)")
set(ICU_MSVC_VERSION "MSVC2022" CACHE STRING "ICU MSVC version (e.g. MSVC2022)")

# バージョン番号のメジャー部分だけ
string(REGEX MATCH "^[0-9]+" ICU_VER "${ICU_VERSION}") 

project(minikin VERSION 0.1.0)
set(PROJ_NAME minikin)

# icudata を内臓させずにスタブだけにする
# ext/icu にも影響します
option(ICU_USE_STUBDATA "Use stubdata instead of real data (for testing)" OFF)

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

# ICU / HarfBuzz: 親プロジェクトが既に同名 target を提供しているなら
# (krkrz_dev umbrella の cmake/CommonExternals.cmake が典型) それを再利用する。
if(NOT TARGET icucommon)
    add_subdirectory(${PROJECT_SOURCE_DIR}/ext/icu)
endif()

if(NOT TARGET harfbuzz)
    add_subdirectory(${PROJECT_SOURCE_DIR}/ext/harfbuzz)
endif()

# ==============================================================================
# リンク設定
# ==============================================================================
target_link_libraries(${PROJ_NAME} PUBLIC 
  freetype
  icucommon 
  harfbuzz 
)

# スタブデータをつくらない場合は icudata をライブラリとしてリンク
if (NOT ICU_USE_STUBDATA)

# ==============================================================================
# ICU データ (同梱 .dat.gz を C ソース化し、ここで直接コンパイル)
# ==============================================================================
# 以前は icudata/Makefile が objcopy で .dat を .o に埋め込み、それを静的
# ライブラリ化して IMPORTED していた。しかし objcopy は出力フォーマット
# (pe/elf/mach-o) やアーキ、シンボルのアンダースコアをターゲットごとに
# 指定する必要があり、GNU objcopy は mach-o を生成できないため macOS
# ビルドが破綻していた。
#
# 現在は ICU データパッケージ (.dat) を gzip 圧縮してリポジトリに同梱し
# (icudata/icudt${ICU_VER}l.dat.gz)、ビルド時に Python (gen_icudata_c.py) で
# 解凍しつつ C ソース (シンボル icudt${ICU_VER}_dat、16 バイト整列、
# 先頭=データ先頭バイト) に変換、その .c をこのプロジェクトのコンパイラで
# 直接コンパイルする。
#   * objcopy / ar / アーキ別フラグが一切不要 → 全プラットフォーム共通。
#   * 通常ビルドに ICU ネイティブツール (bin64 等) も make も不要
#     (Python さえあればよい)。clone 一発でビルドできる。
# .dat.gz の更新 (filters.json や ICU バージョン変更時) は
#   icudata/ で `make update-bundle` を実行 → 生成された .dat.gz をコミット。
set(ICU_DATA_DIR ${PROJECT_SOURCE_DIR}/icudata)
set(ICU_DATA_OUTPUT_DIR ${PROJECT_BINARY_DIR})
set(ICU_DATA_BUNDLE ${ICU_DATA_DIR}/icudt${ICU_VER}l.dat.gz)
set(ICU_DATA_GEN ${ICU_DATA_DIR}/gen_icudata_c.py)
set(ICU_DATA_CSRC ${ICU_DATA_OUTPUT_DIR}/icudata_build/csrc/icudt${ICU_VER}_dat.c)

# C ソース生成には Python 3 のみ必要 (追加モジュール不要)
find_package(Python3 COMPONENTS Interpreter REQUIRED)

message(STATUS "ICU data bundle: ${ICU_DATA_BUNDLE}")
message(STATUS "ICU data C source: ${ICU_DATA_CSRC}")

if(NOT EXISTS ${ICU_DATA_BUNDLE})
    message(FATAL_ERROR
        "ICU data bundle not found: ${ICU_DATA_BUNDLE}\n"
        "Generate it on a host with ICU tools: cd icudata && make update-bundle")
endif()

# 同梱 .dat.gz を解凍しつつ C ソース化するカスタムコマンド
add_custom_command(
    OUTPUT ${ICU_DATA_CSRC}
    COMMAND ${Python3_EXECUTABLE} ${ICU_DATA_GEN}
        --input ${ICU_DATA_BUNDLE}
        --output ${ICU_DATA_CSRC}
        --symbol icudt${ICU_VER}_dat
    DEPENDS ${ICU_DATA_BUNDLE} ${ICU_DATA_GEN}
    COMMENT "Generating ICU data C source from bundled .dat.gz..."
    VERBATIM
)

# 生成される C ソースは構成時点では存在しないため GENERATED 扱いにする
set_source_files_properties(${ICU_DATA_CSRC} PROPERTIES GENERATED TRUE)

# ICU データを静的ライブラリとしてビルド (生成 C ソースを直接コンパイル)
add_library(icudata STATIC ${ICU_DATA_CSRC})

# 巨大な単一データファイルのため最適化やデバッグ情報は不要 (ビルド高速化)
if(NOT MSVC)
    target_compile_options(icudata PRIVATE -O0)
endif()

# ==============================================================================
# リンク設定
# ==============================================================================
target_link_libraries(${PROJ_NAME} PUBLIC
  icudata
)
endif()
