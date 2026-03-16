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

# ICU 77.1 (GitHub からソース取得してビルド)
add_subdirectory(${PROJECT_SOURCE_DIR}/ext/icu)

# HarfBuzz 13.1.1 (GitHub から取得、freetype と ICU に依存)
add_subdirectory(${PROJECT_SOURCE_DIR}/ext/harfbuzz)

# ==============================================================================
# ICU データライブラリ (icudata ディレクトリで Makefile によりビルド)
# ==============================================================================
set(ICU_DATA_DIR ${PROJECT_SOURCE_DIR}/icudata)
set(ICU_DATA_OUTPUT_DIR ${PROJECT_BINARY_DIR})
set(ICU_DATA_LIB ${ICU_DATA_OUTPUT_DIR}/icudata_build/lib/libicudt77.a)

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
    
    # アーキテクチャ別の objcopy 設定
    # CMakePresets.json から明示的に設定されていない場合、プラットフォームに応じて自動判定
    if(NOT DEFINED ICU_DATA_OBJFORMAT OR NOT DEFINED ICU_DATA_OBJARCH OR NOT DEFINED ICU_DATA_ADD_UNDERSCORE)
        # 64bit/32bit 判定
        if(CMAKE_SIZEOF_VOID_P EQUAL 8)
            set(_IS_64BIT TRUE)
        else()
            set(_IS_64BIT FALSE)
        endif()
        
        # プロセッサアーキテクチャ判定 (arm64/aarch64 かどうか)
        string(TOLOWER "${CMAKE_SYSTEM_PROCESSOR}" _PROC_LOWER)
        if(_PROC_LOWER MATCHES "aarch64|arm64")
            set(_IS_ARM64 TRUE)
        else()
            set(_IS_ARM64 FALSE)
        endif()
        
        if(ANDROID)
            # Android
            set(ICU_DATA_ADD_UNDERSCORE "")
            if(_IS_ARM64)
                set(ICU_DATA_OBJFORMAT "elf64-littleaarch64")
                set(ICU_DATA_OBJARCH "aarch64")
            else()
                # x86_64 Android
                set(ICU_DATA_OBJFORMAT "elf64-x86-64")
                set(ICU_DATA_OBJARCH "i386:x86-64")
            endif()
        elseif(CMAKE_SYSTEM_NAME STREQUAL "Windows" OR WIN32)
            # Windows
            if(_IS_64BIT)
                set(ICU_DATA_OBJFORMAT "pe-x86-64")
                set(ICU_DATA_OBJARCH "i386:x86-64")
                set(ICU_DATA_ADD_UNDERSCORE "")
            else()
                set(ICU_DATA_OBJFORMAT "pe-i386")
                set(ICU_DATA_OBJARCH "i386")
                set(ICU_DATA_ADD_UNDERSCORE "1")
            endif()
        elseif(CMAKE_SYSTEM_NAME STREQUAL "Darwin" OR APPLE)
            # macOS
            set(ICU_DATA_ADD_UNDERSCORE "1")
            if(_IS_ARM64)
                set(ICU_DATA_OBJFORMAT "mach-o-arm64")
                set(ICU_DATA_OBJARCH "aarch64")
            else()
                set(ICU_DATA_OBJFORMAT "mach-o-x86-64")
                set(ICU_DATA_OBJARCH "i386:x86-64")
            endif()
        elseif(CMAKE_SYSTEM_NAME STREQUAL "Linux" OR UNIX)
            # Linux / その他 UNIX
            set(ICU_DATA_ADD_UNDERSCORE "")
            if(_IS_ARM64)
                set(ICU_DATA_OBJFORMAT "elf64-littleaarch64")
                set(ICU_DATA_OBJARCH "aarch64")
            elseif(_IS_64BIT)
                set(ICU_DATA_OBJFORMAT "elf64-x86-64")
                set(ICU_DATA_OBJARCH "i386:x86-64")
            else()
                set(ICU_DATA_OBJFORMAT "elf32-i386")
                set(ICU_DATA_OBJARCH "i386")
            endif()
        else()
            # フォールバック: x64-windows 互換
            message(WARNING "Unknown platform: ${CMAKE_SYSTEM_NAME}/${CMAKE_SYSTEM_PROCESSOR}, using x64-windows defaults")
            set(ICU_DATA_OBJFORMAT "pe-x86-64")
            set(ICU_DATA_OBJARCH "i386:x86-64")
            set(ICU_DATA_ADD_UNDERSCORE "")
        endif()
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
