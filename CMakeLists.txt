# MEMO
# VSCode の Cmake ext. でデフォルト生成したときのv3.0.0 だと
# ポリシーCMP0057 に引っかかって harfbuzz が取り込めないので注意
cmake_minimum_required(VERSION 3.15.0)

# vcpkg対応(これは必ずprojectコマンドの前にすること)
# harfbuzz-icu-freetype を使用する場合でも libpng は vcpkg 参照になっているので必要
if(DEFINED ENV{VCPKG_ROOT} AND NOT DEFINED CMAKE_TOOLCHAIN_FILE)
  set(CMAKE_TOOLCHAIN_FILE "$ENV{VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake"
      CACHE STRING "")
endif()

# vcpkg static を使用
set(VCPKG_TARGET_TRIPLET x64-windows-static CACHE STRING "")

project(minikin VERSION 0.1.0)
set(PROJ_NAME minikin)

file(GLOB SOURCES "libs/minikin/*.cpp")
add_library(${PROJ_NAME} ${SOURCES})

# 未定義実装を置き換えるための強制インクルードヘッダを指定する
if(MSVC)
  set(MSVC_GLOBAL_OPTIONS /utf-8 /wd4819 /wd4996 /wd4244 /wd4018 /MP)
  target_compile_options(${PROJ_NAME} PRIVATE /FI"_stub.h" ${MSVC_GLOBAL_OPTIONS})
  # harfbuzz-icu-freetype のビルドでコケるのでグローバルにUTF8オプション付与
  # ついでに並列ビルドと各種Warn抑制(コードページ、unsigned比較等)
  add_compile_options(${MSVC_GLOBAL_OPTIONS})
else()
  # GCC or Clang
  target_compile_options(${PROJ_NAME} PRIVATE -include _stub.h)
endif()

# インクルードパス
# libs/ は本来内部実装用の非公開パスだが全部見えるようにしておく(テスト向け)
target_include_directories(${PROJ_NAME} PUBLIC libs include)

# 一部機能が C++17 を要求するので
target_compile_features(${PROJ_NAME} PRIVATE cxx_std_17)

# Wamsoft の変更部分を有効にする
add_compile_definitions(WAMSOFT_MODIFIED)

# FT の png フォント対応用
find_package(libpng CONFIG REQUIRED)
target_link_libraries(${PROJ_NAME} PRIVATE png_static)
find_package(ZLIB REQUIRED)
target_link_libraries(${PROJ_NAME} PRIVATE ZLIB::ZLIB)

# FT/HB/ICU を vcpkg で参照するか、harfbuzz-icu-freetype で参照するか
option(USE_VCPKG "Build with vcpkg packages." OFF)
if(USE_VCPKG)
  # vcpkg: GoogleTest, FreeType, HarfBuzz、ICU
  find_package(freetype CONFIG REQUIRED)
  find_package(harfbuzz CONFIG REQUIRED)
  find_package(ICU REQUIRED COMPONENTS uc i18n data io)
  target_link_libraries(${PROJ_NAME} PRIVATE freetype)
  target_link_libraries(${PROJ_NAME} PRIVATE harfbuzz harfbuzz::harfbuzz)
  target_link_libraries(icutest PRIVATE ICU::uc ICU::i18n ICU::data ICU::io)
else()
  # Harfbuzz ICU Freetype
  # minikinの配下に配置すること
  set(FT_WITH_PNG ON CACHE BOOL "Enable FT with PNG")
  set(FT_WITH_ZLIB ON CACHE BOOL "Enable FT with ZLIB")
  set(HARFBUZZ_BUILD_ICU ON CACHE BOOL "Enable building of ICU")
  set(HARFBUZZ_BUILD_UCDN ON CACHE BOOL "Enable building of UCDN")
  add_subdirectory(${PROJECT_SOURCE_DIR}/harfbuzz-icu-freetype)
  target_link_libraries(${PROJ_NAME} PUBLIC harfbuzz icucommon freetype)
  # harfbuzz-icu-freetype のライブラリをすべて /MT(d) でビルドする
  set_property(TARGET harfbuzz icucommon freetype 
    PROPERTY MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
  # ICU のリソースデータをリンク
  if(CMAKE_SIZEOF_VOID_P EQUAL 8) # 64 bits
    target_link_libraries(${PROJ_NAME} PRIVATE
      ${CMAKE_CURRENT_SOURCE_DIR}/icudata/lib64/icudt67.lib)
  elseif(CMAKE_SIZEOF_VOID_P EQUAL 4) # 32 bits
    target_link_libraries(${PROJ_NAME} PRIVATE
      ${CMAKE_CURRENT_SOURCE_DIR}/icudata/lib/icudt67.lib)
  endif()
endif(USE_VCPKG)
unset(USE_VCPKG CACHE) # 消しておかないと、Cmakeキャッシュに残って面倒になる

# /MT(d) でビルドする
set_property(TARGET ${PROJ_NAME} 
  PROPERTY MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")