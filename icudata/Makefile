# ==============================================================================
# ICU データリソースビルド設定
# ==============================================================================

# ICU バージョン設定
ICU_VER = 77
ICU_VERSION_TAG = 77-1
MSVC_VERSION = MSVC2022

# エンディアン指定 (l=little-endian, b=big-endian)
LIB_CHAR = l

# ==============================================================================
# アーキテクチャ設定 (デフォルト: 64bit)
# ==============================================================================
# 64bit (デフォルト):
#   OBJFORMAT = pe-x86-64
#   OBJARCH = i386:x86-64
#   ADD_UNDERSCORE =
#
# 32bit の場合は以下を指定:
#   OBJFORMAT = pe-i386
#   OBJARCH = i386
#   ADD_UNDERSCORE = 1
#
# Linux 64bit:
#   OBJFORMAT = elf64-x86-64
#   OBJARCH = i386:x86-64
#
# Linux 32bit:
#   OBJFORMAT = elf32-i386
#   OBJARCH = i386
#   ADD_UNDERSCORE = 1

OBJFORMAT ?= pe-x86-64
OBJARCH ?= i386:x86-64
ADD_UNDERSCORE ?=

# ==============================================================================
# ディレクトリ設定
# ==============================================================================

# 絶対パスのベース (Makefile のあるディレクトリ)
ROOT_DIR := $(CURDIR)

# ビルド出力先 (プロジェクト直下の build/icudata)
BUILD_DIR = $(ROOT_DIR)/../build/icudata

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
OBJ_DIR = $(OUTPUT_DIR)/icudata_build/obj
DAT_DIR = $(OUTPUT_DIR)/icudata_build/dat
LIB_DIR = $(OUTPUT_DIR)/icudata_build/lib

# Python venv 環境 (共有、BUILD_DIR 固定)
VENV_DIR = $(BUILD_DIR)/venv
PYTHON = $(VENV_DIR)/Scripts/python.exe

# ==============================================================================
# 出力ファイル名
# ==============================================================================

LIB_NAME = icudt$(ICU_VER)
DATA_NAME = icudt$(ICU_VER)$(LIB_CHAR)
PKGDATA_LIST = $(TMP_DIR)/icudata.lst
DAT_FILE = $(DAT_DIR)/$(DATA_NAME).dat
OBJ_FILE = $(OBJ_DIR)/$(DATA_NAME).o
LIB_FILE = $(LIB_DIR)/lib$(LIB_NAME).a

# ICU エントリポイントシンボル (icudt67_dat 形式)
ICU_ENTRY_SYMBOL = $(LIB_NAME)_dat

# objcopy が生成するデフォルトシンボルのベース名
BINARY_SYMBOL_BASE = _binary_$(DATA_NAME)_dat

# ==============================================================================
# ツール設定
# ==============================================================================

OBJCOPY ?= objcopy
AR ?= ar

# ==============================================================================
# ターゲット
# ==============================================================================

.PHONY: all clean clean-lib clean-all prepare check-tools setup-venv lib datfile

.SUFFIXES:

# デフォルトターゲット
all: lib

# 静的ライブラリ作成
lib: $(LIB_FILE)

# .dat ファイルのみ作成
datfile: $(DAT_FILE)

# ==============================================================================
# prepare: 必要なファイルが存在しない場合にダウンロードを実行
# ==============================================================================

prepare: check-tools
	@if [ ! -d "$(DATA_DIR)" ] || [ ! -d "$(TOOL_DIR)" ] || [ ! -d "$(ICUTOOLS_DIR)" ]; then \
		echo "=== Downloading ICU data from GitHub ==="; \
		bash $(DOWNLOAD_SCRIPT) $(ICU_VERSION_TAG) $(BUILD_DIR) $(MSVC_VERSION); \
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
		py -3 -m venv $(VENV_DIR); \
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

clean-lib:
	rm -rf $(LIB_DIR) $(OBJ_DIR) $(DAT_DIR)

# ダウンロードしたデータも含めて全てクリーン
clean-all:
	rm -rf $(BUILD_DIR)

# ==============================================================================
# ビルドルール
# ==============================================================================

# 静的ライブラリ作成
$(LIB_FILE): $(OBJ_FILE)
	@echo "== create static lib =="
	@mkdir -p $(LIB_DIR)
	$(AR) rcs $(LIB_FILE) $(OBJ_FILE)
	@echo "Created: $(LIB_FILE)"

# オブジェクトファイル作成 (objcopy)
$(OBJ_FILE): $(DAT_FILE)
	@echo "== convert .dat to object =="
	@mkdir -p $(OBJ_DIR)
ifdef ADD_UNDERSCORE
	cd $(DAT_DIR) && $(OBJCOPY) \
		-I binary \
		-O $(OBJFORMAT) \
		-B $(OBJARCH) \
		--rename-section .data=.rodata,alloc,load,readonly,data,contents \
		--add-leading-underscore \
		--redefine-sym _$(BINARY_SYMBOL_BASE)_start=_$(ICU_ENTRY_SYMBOL) \
		$(DATA_NAME).dat $(OBJ_FILE)
else
	cd $(DAT_DIR) && $(OBJCOPY) \
		-I binary \
		-O $(OBJFORMAT) \
		-B $(OBJARCH) \
		--rename-section .data=.rodata,alloc,load,readonly,data,contents \
		--redefine-sym $(BINARY_SYMBOL_BASE)_start=$(ICU_ENTRY_SYMBOL) \
		$(DATA_NAME).dat $(OBJ_FILE)
endif

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
$(PKGDATA_LIST): prepare setup-venv
	@echo "== build resources =="
	PYTHONPATH=$(BUILD_DIR) COMSPEC=powershell $(PYTHON) -B -m icutools.databuilder --mode unix-exec \
		--src_dir $(DATA_DIR) --out_dir $(OUT_DIR) --tmp_dir $(TMP_DIR) \
		--tool_dir $(TOOL_DIR) --filter_file $(FILTER_FILE)
