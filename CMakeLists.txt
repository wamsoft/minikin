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

# ==============================================================================
# ICU データライブラリ (icudata ディレクトリで Makefile によりビルド)
# ==============================================================================
set(ICU_DATA_DIR ${PROJECT_SOURCE_DIR}/icudata)
set(ICU_DATA_OUTPUT_DIR ${PROJECT_BINARY_DIR})
set(ICU_DATA_LIB ${ICU_DATA_OUTPUT_DIR}/icudata_build/lib/libicudt78.a)

# ICU データライブラリをビルドするカスタムターゲット
# Windows では MSYS2/Git Bash 環境の make を想定
find_program(MAKE_EXECUTABLE NAMES make mingw32-make gmake
    HINTS 
        "$ENV{MSYS2_ROOT}/usr/bin"
        "C:/msys64/usr/bin"
        "$ENV{ProgramFiles}/Git/usr/bin"
)

if(MAKE_EXECUTABLE)
    message(STATUS "Found make: ${MAKE_EXECUTABLE}")
    
    # アーキテクチャ別の objcopy 設定 (CMakePresets.json から設定可能)
    # デフォルト値は x64-windows 用
    if(NOT DEFINED ICU_DATA_OBJFORMAT)
        set(ICU_DATA_OBJFORMAT "pe-x86-64")
    endif()
    if(NOT DEFINED ICU_DATA_OBJARCH)
        set(ICU_DATA_OBJARCH "i386:x86-64")
    endif()
    if(NOT DEFINED ICU_DATA_ADD_UNDERSCORE)
        set(ICU_DATA_ADD_UNDERSCORE "")
    endif()
    
    message(STATUS "ICU data: OBJFORMAT=${ICU_DATA_OBJFORMAT}, OBJARCH=${ICU_DATA_OBJARCH}, ADD_UNDERSCORE=${ICU_DATA_ADD_UNDERSCORE}")
    message(STATUS "ICU data output: ${ICU_DATA_OUTPUT_DIR}/icudata_build/")
    
    # ICU データライブラリが存在しない場合にビルドするカスタムコマンド
    add_custom_command(
        OUTPUT ${ICU_DATA_LIB}
        COMMAND ${MAKE_EXECUTABLE} lib
            OUTPUT_DIR=${ICU_DATA_OUTPUT_DIR}
            OBJFORMAT=${ICU_DATA_OBJFORMAT}
            OBJARCH=${ICU_DATA_OBJARCH}
            ADD_UNDERSCORE=${ICU_DATA_ADD_UNDERSCORE}
        WORKING_DIRECTORY ${ICU_DATA_DIR}
        COMMENT "Building ICU data library..."
        VERBATIM
    )
    
    # カスタムターゲット (明示的にビルドする場合)
    add_custom_target(icudata_build
        DEPENDS ${ICU_DATA_LIB}
        COMMENT "ICU data library target"
    )
else()
    message(WARNING "make not found. ICU data library must be built manually: cd icudata && make lib")
    
    # ダミーターゲット
    add_custom_target(icudata_build
        COMMENT "ICU data library (manual build required)"
    )
endif()

# ICU データをインポートライブラリとして定義
add_library(icudata STATIC IMPORTED GLOBAL)
set_target_properties(icudata PROPERTIES
    IMPORTED_LOCATION ${ICU_DATA_LIB}
)

# ==============================================================================
# リンク設定
# ==============================================================================
target_link_libraries(${PROJ_NAME} PUBLIC 
  freetype
  icucommon 
  harfbuzz 
  icudata
)

# minikin が icudata_build に依存するように設定
# (IMPORTED ライブラリには直接依存関係を設定できないため)
if(MAKE_EXECUTABLE)
    add_dependencies(${PROJ_NAME} icudata_build)
endif()
