SHELL = /bin/bash

ifeq ($(shell type cygpath >& /dev/null && echo true),true)
FIXPATH = cygpath -ma
else
FIXPATH = realpath
endif

# ==============================================================================
# ICU データリソースビルド設定
# ==============================================================================

# ICU バージョン設定
ICU_VERSION ?= 77.1
ICU_VERSION_TAG ?= 77-1
ICU_MSVC_VERSION ?= MSVC2022

# メジャーバージョン
ICU_VER = $(firstword $(subst ., ,$(ICU_VERSION)))

# エンディアン指定 (l=little-endian, b=big-endian)
LIB_CHAR = l

# ==============================================================================
# .dat -> C ソース変換について
# ==============================================================================
# 以前は objcopy で .dat を直接 .o に埋め込み、それを静的ライブラリ化して
# いた。しかし objcopy は出力フォーマット (pe/elf/mach-o) やアーキテクチャ、
# シンボルのアンダースコア有無をターゲットごとに指定する必要があり、特に
# GNU objcopy は mach-o を生成できないため macOS ビルドで破綻していた。
#
# 現在は Python (gen_icudata_c.py) で .dat を C ソースに変換する。生成された
# .c は上位 (CMake) がそのプロジェクトのコンパイラで直接コンパイルするため、
# objcopy/ar やアーキ別フラグは一切不要で完全に移植性がある。

# ==============================================================================
# ディレクトリ設定
# ==============================================================================

# 絶対パスのベース (Makefile のあるディレクトリ)
ROOT_DIR := $(CURDIR)

# ビルド出力先 (プロジェクト直下の build/icudata)
BUILD_DIR = $(shell $(FIXPATH) "$(ROOT_DIR)/../build/icudata")

# 出力先ディレクトリ (外部から指定可能、デフォルトは BUILD_DIR)
# cmake から OUTPUT_DIR=<path> で指定することで、各ビルドフォルダに出力可能
OUTPUT_DIR ?= $(BUILD_DIR)

# GitHubからダウンロードしたデータの配置先 (共有、BUILD_DIR 固定)
DATA_DIR = $(BUILD_DIR)/data
TOOL_DIR = $(BUILD_DIR)/bin64
ICUTOOLS_DIR = $(BUILD_DIR)/icutools

# ローカルファイル (このディレクトリ内)
FILTER_FILE = $(ROOT_DIR)/filters.json
DOWNLOAD_SCRIPT = $(ROOT_DIR)/download_icu_data.sh
REQUIREMENTS_FILE = $(ROOT_DIR)/requirements.txt

# ビルド作業用ディレクトリ (OUTPUT_DIR 配下)
OUT_DIR = $(OUTPUT_DIR)/icudata_build/out
TMP_DIR = $(OUTPUT_DIR)/icudata_build/tmp
DAT_DIR = $(OUTPUT_DIR)/icudata_build/dat
CSRC_DIR = $(OUTPUT_DIR)/icudata_build/csrc

# Python venv 環境 (共有、BUILD_DIR 固定)
VENV_DIR = $(BUILD_DIR)/venv

# venv 作成に使う Python ランチャーと、venv 内 Python のパス
# Windows: py ランチャー (py -3)、venv は Scripts/python.exe
# それ以外: python3、venv は bin/python
ifeq ($(OS),Windows_NT)
PY ?= py -3
PYTHON = $(VENV_DIR)/Scripts/python.exe
else
PY ?= python3
PYTHON = $(VENV_DIR)/bin/python
endif

# ==============================================================================
# 出力ファイル名
# ==============================================================================

LIB_NAME = icudt$(ICU_VER)
DATA_NAME = icudt$(ICU_VER)$(LIB_CHAR)
PKGDATA_LIST = $(TMP_DIR)/icudata.lst
DAT_FILE = $(DAT_DIR)/$(DATA_NAME).dat

# リポジトリに同梱する圧縮済み .dat (clone 一発で取得できる成果物)。
# 通常ビルドはこれを Python で解凍して C ソース化するため、ICU ネイティブ
# ツール (bin64 等) も make も不要 (Windows/Linux/macOS 共通で動作)。
# filters.json や ICU バージョンを変えたときだけ update-bundle で更新する。
BUNDLED_DAT_GZ = $(ROOT_DIR)/$(DATA_NAME).dat.gz

# ICU エントリポイントシンボル (icudt77_dat 形式)
# ICU 側 (common/udata.cpp) の U_ICUDATA_ENTRY_POINT と一致させる必要がある。
ICU_ENTRY_SYMBOL = $(LIB_NAME)_dat

# 生成する C ソース (このファイル名は上位 CMake からも参照される)
C_FILE = $(CSRC_DIR)/$(ICU_ENTRY_SYMBOL).c

# .dat -> C ソース変換スクリプト
GEN_SCRIPT = $(ROOT_DIR)/gen_icudata_c.py

# C ソース生成に使う Python (上位 CMake は自前の Python を直接渡す。
# ここでは make 単体実行向けに、venv があればそれ、無ければ素の python を使う)
ifeq ($(OS),Windows_NT)
GEN_PYTHON ?= $(if $(wildcard $(PYTHON)),$(PYTHON),py -3)
else
GEN_PYTHON ?= $(if $(wildcard $(PYTHON)),$(PYTHON),python3)
endif

# ==============================================================================
# ターゲット
# ==============================================================================

.PHONY: all clean clean-gen clean-all prepare check-tools setup-venv csource datfile update-bundle

.SUFFIXES:

# デフォルトターゲット: 同梱 .dat.gz から C ソースを生成する
all: csource

# .dat を埋め込んだ C ソースを生成 (上位 CMake がこれをコンパイルする)
csource: $(C_FILE)

# .dat ファイルのみ作成 (ICU ツールで一から再ビルド。要 bin64 等)
datfile: $(DAT_FILE)

# 同梱用 .dat.gz を更新する (メンテナ用)。
# filters.json や ICU バージョンを変更したら、ツールが揃ったホスト
# (Windows / Linux-x64) でこれを実行し、生成された .dat.gz をコミットする。
update-bundle: $(DAT_FILE)
	@echo "== update bundled $(notdir $(BUNDLED_DAT_GZ)) =="
	gzip -9 -n -c $(DAT_FILE) > $(BUNDLED_DAT_GZ)
	@echo "Updated: $(BUNDLED_DAT_GZ)"
	@echo "  -> このファイルをコミットしてください。"

# ==============================================================================
# prepare: 必要なファイルが存在しない場合にダウンロードを実行
# ==============================================================================

prepare: check-tools
	@if [ ! -d "$(DATA_DIR)" ] || [ ! -d "$(TOOL_DIR)" ] || [ ! -d "$(ICUTOOLS_DIR)" ]; then \
		echo "=== Downloading ICU data from GitHub ==="; \
		bash $(DOWNLOAD_SCRIPT) $(ICU_VERSION_TAG) $(BUILD_DIR) $(ICU_MSVC_VERSION); \
	else \
		echo "=== ICU data already exists, skipping download ==="; \
	fi

# curl または wget の存在確認
check-tools:
	@command -v curl >/dev/null 2>&1 || command -v wget >/dev/null 2>&1 || \
		(echo "Error: curl or wget is required for downloading" && exit 1)
	@command -v unzip >/dev/null 2>&1 || \
		(echo "Error: unzip is required for extracting" && exit 1)

# Python venv 環境のセットアップ
setup-venv:
	@if [ ! -f "$(PYTHON)" ]; then \
		echo "=== Setting up Python venv ==="; \
		$(PY) -m venv $(VENV_DIR); \
		$(PYTHON) -m pip install --upgrade pip; \
		$(PYTHON) -m pip install -r $(REQUIREMENTS_FILE); \
	else \
		echo "=== Python venv already exists ==="; \
	fi

# ==============================================================================
# クリーンターゲット
# ==============================================================================

clean:
	rm -rf $(OUT_DIR) $(TMP_DIR)

clean-gen:
	rm -rf $(CSRC_DIR) $(DAT_DIR)

# ダウンロードしたデータも含めて全てクリーン
clean-all:
	rm -rf $(BUILD_DIR)

# ==============================================================================
# ビルドルール
# ==============================================================================

# 同梱 .dat.gz を埋め込んだ C ソースを生成 (objcopy の代替)
# 出力は 16 バイト整列・先頭=データ先頭バイトの C 配列。シンボル名は
# ICU_ENTRY_SYMBOL (= icudt77_dat)。これを上位 CMake が直接コンパイルする。
# 入力は同梱済みの .dat.gz なので ICU ネイティブツールは不要。
$(C_FILE): $(BUNDLED_DAT_GZ) $(GEN_SCRIPT)
	@echo "== generate C source from bundled .dat.gz =="
	@mkdir -p $(CSRC_DIR)
	$(GEN_PYTHON) $(GEN_SCRIPT) --input $(BUNDLED_DAT_GZ) --output $(C_FILE) --symbol $(ICU_ENTRY_SYMBOL)
	@echo "Created: $(C_FILE)"

# .dat パッケージファイル作成 (icupkg)
$(DAT_FILE): $(PKGDATA_LIST)
	@echo "== create .dat package =="
	@mkdir -p $(DAT_DIR)
	cd $(OUT_DIR) && $(TOOL_DIR)/icupkg -t$(LIB_CHAR) -a $(PKGDATA_LIST) new $(DAT_FILE)
	@echo "Created: $(DAT_FILE)"

# リソースファイル (.res) ビルド (databuilder)
# --mode で windows-exec を指定すると、起動するコマンドのパスが
# <bindir>/<cmd>/<tool_cfg>/<cmd>.exe に固定されてうまく実行できない。
# unix-exec を指定すると <bindir>/<cmd> で実行されるのでその問題は無いが、
# その代わりで MSYS では COMSPEC に powershell を指定してやらないと 
# ./bin/hoge.exe みたいなパス指定でコマンドが起動できない。
# PYTHONPATH は icutools の親ディレクトリを指定 (icutools.databuilder として呼び出すため)
$(PKGDATA_LIST): prepare setup-venv $(FILTER_FILE)
	@echo "== build resources =="
	PYTHONPATH=$(BUILD_DIR)  $(PYTHON) -B -m icutools.databuilder --mode unix-exec \
		--src_dir $(DATA_DIR) --out_dir $(OUT_DIR) --tmp_dir $(TMP_DIR) \
		--tool_dir $(TOOL_DIR) --filter_file $(FILTER_FILE)
