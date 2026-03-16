#!/bin/bash
# ICU data/tools をGitHubからダウンロードして展開するスクリプト
# Usage: ./download_icu_data.sh [ICU_VERSION] [OUTPUT_DIR] [MSVC_VERSION]
#   ICU_VERSION:  ICUのバージョン (例: 67-1) デフォルト: 67-1
#   OUTPUT_DIR:   出力先ディレクトリ デフォルト: ../build/icudata
#   MSVC_VERSION: MSVCバージョン (例: MSVC2017, MSVC2019) デフォルト: MSVC2017

set -e

# 引数またはデフォルト値
ICU_VERSION="${1:-67-1}"
OUTPUT_DIR="${2:-../build/icudata}"
MSVC_VERSION="${3:-MSVC2017}"

# バージョン文字列の変換 (67-1 -> 67_1 for filename)
ICU_VERSION_UNDERSCORE="${ICU_VERSION//-/_}"
# リリースタグ用 (67-1 -> release-67-1)
ICU_RELEASE_TAG="release-${ICU_VERSION}"

# GitHub Release URL
GITHUB_RELEASE_BASE="https://github.com/unicode-org/icu/releases/download/${ICU_RELEASE_TAG}"

# ダウンロードするファイル
DATA_ZIP="icu4c-${ICU_VERSION_UNDERSCORE}-data.zip"
WIN64_ZIP="icu4c-${ICU_VERSION_UNDERSCORE}-Win64-${MSVC_VERSION}.zip"
SRC_ZIP="icu4c-${ICU_VERSION_UNDERSCORE}-sources.zip"

# 一時ディレクトリ
TEMP_DIR="${OUTPUT_DIR}/_temp"

echo "=== ICU Data Download Script ==="
echo "ICU Version: ${ICU_VERSION}"
echo "MSVC Version: ${MSVC_VERSION}"
echo "Output Dir: ${OUTPUT_DIR}"
echo ""

# 出力ディレクトリ作成
mkdir -p "${OUTPUT_DIR}"
mkdir -p "${TEMP_DIR}"

# ダウンロード関数
download_file() {
    local url="$1"
    local output="$2"
    echo "Downloading: ${url}"
    if command -v curl &> /dev/null; then
        curl -L -o "${output}" "${url}"
    elif command -v wget &> /dev/null; then
        wget -O "${output}" "${url}"
    else
        echo "Error: curl or wget is required"
        exit 1
    fi
}

# data/ のダウンロードと展開
download_and_extract_data() {
    if [ -d "${OUTPUT_DIR}/data" ]; then
        echo "data/ already exists, skipping..."
        return
    fi
    echo ""
    echo "=== Downloading ICU Data ==="
    download_file "${GITHUB_RELEASE_BASE}/${DATA_ZIP}" "${TEMP_DIR}/${DATA_ZIP}"
    echo "Extracting ${DATA_ZIP}..."
    mkdir -p "${OUTPUT_DIR}/data"
    unzip -q "${TEMP_DIR}/${DATA_ZIP}" -d "${TEMP_DIR}/data_tmp"
    # ZIPの構造に応じてコピー (data/ または直接ファイル)
    if [ -d "${TEMP_DIR}/data_tmp/data" ]; then
        cp -r "${TEMP_DIR}/data_tmp/data"/* "${OUTPUT_DIR}/data/"
    else
        cp -r "${TEMP_DIR}/data_tmp"/* "${OUTPUT_DIR}/data/"
    fi
    rm -rf "${TEMP_DIR}/data_tmp"
    echo "data/ extracted successfully"
}

# bin64/ (Win64) のダウンロードと展開
download_and_extract_bin64() {
    if [ -d "${OUTPUT_DIR}/bin64" ]; then
        echo "bin64/ already exists, skipping..."
        return
    fi
    echo ""
    echo "=== Downloading ICU Win64 Tools ==="
    download_file "${GITHUB_RELEASE_BASE}/${WIN64_ZIP}" "${TEMP_DIR}/${WIN64_ZIP}"
    echo "Extracting ${WIN64_ZIP}..."
    mkdir -p "${OUTPUT_DIR}/bin64"
    unzip -q "${TEMP_DIR}/${WIN64_ZIP}" -d "${TEMP_DIR}/win64_tmp"
    # bin64/ 配下を抽出 (ZIPの構造に応じて icu/bin64 または bin64 を参照)
    if [ -d "${TEMP_DIR}/win64_tmp/icu/bin64" ]; then
        cp -r "${TEMP_DIR}/win64_tmp/icu/bin64"/* "${OUTPUT_DIR}/bin64/"
    elif [ -d "${TEMP_DIR}/win64_tmp/bin64" ]; then
        cp -r "${TEMP_DIR}/win64_tmp/bin64"/* "${OUTPUT_DIR}/bin64/"
    else
        echo "Error: bin64 directory not found in archive"
        exit 1
    fi
    rm -rf "${TEMP_DIR}/win64_tmp"
    echo "bin64/ extracted successfully"
}

# icutools/ のダウンロードと展開
download_and_extract_icutools() {
    if [ -d "${OUTPUT_DIR}/icutools" ]; then
        echo "icutools/ already exists, skipping..."
        return
    fi
    echo ""
    echo "=== Downloading ICU Source (for icutools) ==="
    download_file "${GITHUB_RELEASE_BASE}/${SRC_ZIP}" "${TEMP_DIR}/${SRC_ZIP}"
    echo "Extracting icutools from ${SRC_ZIP}..."
    mkdir -p "${OUTPUT_DIR}/icutools"
    # 全展開してから icutools だけをコピー (ワイルドカードだとサブディレクトリが展開されない問題の回避)
    unzip -q "${TEMP_DIR}/${SRC_ZIP}" -d "${TEMP_DIR}/src_tmp"
    cp -r "${TEMP_DIR}/src_tmp/icu/source/python/icutools"/* "${OUTPUT_DIR}/icutools/"
    rm -rf "${TEMP_DIR}/src_tmp"
    echo "icutools/ extracted successfully"
}

# 実行
download_and_extract_data
download_and_extract_bin64
download_and_extract_icutools

# 一時ファイルのクリーンアップ
echo ""
echo "=== Cleanup ==="
rm -rf "${TEMP_DIR}"
echo "Temporary files removed"

echo ""
echo "=== Done ==="
echo "ICU data has been downloaded to: ${OUTPUT_DIR}"
