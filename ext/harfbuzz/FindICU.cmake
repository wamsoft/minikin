# ==============================================================================
# カスタム FindICU.cmake
# ==============================================================================
# ICU は ext/icu で既にビルドされているため、そのターゲットを使用
# HarfBuzz の find_package(ICU) をバイパスするためのダミーモジュール

# ICU::uc ターゲットが存在するか確認
if(TARGET ICU::uc)
    set(ICU_FOUND TRUE)
    set(ICU_uc_FOUND TRUE)
    set(ICU_VERSION "${ICU_VERSION}" CACHE STRING "ICU version")
    
    # インクルードディレクトリを取得
    get_target_property(ICU_INCLUDE_DIRS ICU::uc INTERFACE_INCLUDE_DIRECTORIES)
    
    message(STATUS "FindICU: Using pre-built ICU::uc target (version ${ICU_VERSION})")
else()
    message(FATAL_ERROR "FindICU: ICU::uc target not found. Ensure ext/icu is built first.")
endif()
