BASE_DIR = .
DATA_DIR = $(BASE_DIR)/data
TOOL32_DIR = $(BASE_DIR)/bin
TOOL64_DIR = $(BASE_DIR)/bin64
OUT_DIR = $(BASE_DIR)/out
TMP_DIR = $(BASE_DIR)/tmp
LIB32_DIR = $(BASE_DIR)/lib
LIB64_DIR = $(BASE_DIR)/lib64

FILTER_FILE = $(BASE_DIR)/filters.json
PKGDATA_LIST = $(BASE_DIR)/tmp/icudata.lst

# ICU_VAR はメジャーバージョンを指定
# LIB_CHAR にはエンディアンによって l or b を指定する
ICU_VER = 67
LIB_CHAR = l
LIB_NAME = icudt$(ICU_VER)
ENTRY_POINT = $(LIB_NAME)
DATA_NAME = icudt$(ICU_VER)$(LIB_CHAR)

# pkgdata の Windows バイナリで static lib 生成をしようとすると
# -O オプションは無視される…。MINGWIN バイナリに置き換えた時は使えるかも？
# PKGDATA_OPTS = -O $(BASE_DIR)/bldopts/windows.txt
PKGDATA_OPTS = 

## List of phony targets
.PHONY: all clean clean-lib packagedata

.SUFFIXES:

all: packagedata

clean:
	rm -rf $(OUT_DIR) $(TMP_DIR)
	
clean-lib:
	rm -rf $(LIB32_DIR) $(LIB64_DIR)

packagedata: $(LIB32_DIR)/$(LIB_NAME).lib $(LIB64_DIR)/$(LIB_NAME).lib

# pkgdata が勝手に頭に s をつけるので mv して本来の名前に戻す
# (名前が icudt～ だと勝手に s をつけるような処理になっている…) 
$(LIB32_DIR)/$(LIB_NAME).lib: $(PKGDATA_LIST)
	@echo "== build 32bit static lib =="
	@mkdir -p $(LIB32_DIR) 
	$(TOOL32_DIR)/pkgdata -m static -T $(TMP_DIR) -e $(ENTRY_POINT) -p $(DATA_NAME) \
		-L $(LIB_NAME) -d $(LIB32_DIR) -s $(OUT_DIR) $(PKGDATA_OPTS) $(PKGDATA_LIST)
	@mv $(LIB32_DIR)/s$(LIB_NAME).lib $(LIB32_DIR)/$(LIB_NAME).lib

$(LIB64_DIR)/$(LIB_NAME).lib: $(PKGDATA_LIST)
	@echo "== build 64bit static lib =="
	@mkdir -p $(LIB64_DIR) 
	$(TOOL64_DIR)/pkgdata -m static -T $(TMP_DIR) -e $(ENTRY_POINT)  -p $(DATA_NAME) \
		-L $(LIB_NAME) -d $(LIB64_DIR) -s $(OUT_DIR) $(PKGDATA_OPTS) $(PKGDATA_LIST)
	@mv $(LIB64_DIR)/s$(LIB_NAME).lib $(LIB64_DIR)/$(LIB_NAME).lib

# --mode で windows-exec を指定すると、起動するコマンドのパスが
# <bindir>/<cmd>/<tool_cfg>/<cmd>.exe に固定されてうまく実行できない。
# (各ツールバイナリを一つずつ <bindir>/<cmd>/<tool_cfg>/<cmd>.exe に
# 配置しなおしても良いが…)。
# unix-exec を指定すると <bindir>/<cmd> で実行されるのでその問題は無いが、
# その代わりで MSYS では COMSPEC に powershell を指定してやらないと 
# ./bin/hoge.exe みたいなパス指定でコマンドが起動できない。
# (subprocess::call() で cmd.exe がキックされて、みたいな理由？)
$(PKGDATA_LIST):
	@echo "== build resources =="
	COMSPEC=powershell py -3 -B -m icutools.databuilder --mode unix-exec \
		--src_dir $(DATA_DIR) --out_dir $(OUT_DIR) --tmp_dir $(TMP_DIR) \
		--tool_dir $(TOOL32_DIR) --filter_file $(FILTER_FILE)
