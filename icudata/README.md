# About

ICU 用のリソースデータの単独でのビルドに
必要なファイル等を集めたディレクトリです。

また、単純に全リソースをビルドすると巨大になりますが、
フィルタ指定により必要なリソースのみをビルドすることが
可能になっています(方法は後述)。

## ディレクトリ構成

```
icudata/
├── Makefile              # ビルド用 Makefile
├── README.md             # このファイル
├── filters.json          # リソースフィルタ設定
├── download_icu_data.sh  # ICU データダウンロードスクリプト
└── requirements.txt      # Python 依存モジュール

../build/icudata/         # ビルド出力先 (自動生成)
├── data/                 # ICU データソース (GitHub からダウンロード)
├── bin64/                # Win64 ツールバイナリ (GitHub からダウンロード)
├── icutools/             # Python ツール (GitHub からダウンロード)
├── venv/                 # Python venv 環境 (hjson 等インストール済み)
├── out/                  # ビルド中間ファイル (.res 等)
├── tmp/                  # 一時ファイル
├── dat/                  # .dat パッケージファイル
├── obj/                  # objcopy 出力 (.o ファイル)
└── lib/                  # static lib 出力先
```

## ICU データの取得

**_[重要] ICU のバージョン上位の ext/icu/CMakeLists.txt で作成する ICU のバージョンに合わせてください。

### 自動ダウンロード (推奨)

`make prepare` を実行すると、必要なファイルが存在しない場合に
GitHub Release から自動的にダウンロードされます。

```bash
cd icudata
make prepare
```

ダウンロードされるファイル:
- `data/` - ICU データソース (`icu4c-XX_X-data.zip`)
- `bin64/` - Win64 ツール (`icu4c-XX_X-Win64-MSVCXXXX.zip`)
- `icutools/` - Python ツール (`icu4c-XX_X-src.zip` から抽出)

### バージョン変更

ICU のバージョンを変更する場合は、`Makefile` 内の以下の変数を編集してください:

```makefile
ICU_VER = 77              # メジャーバージョン番号
ICU_VERSION_TAG = 77_1   # GitHub リリースタグ (release-XX.X 形式)
ICU_MSVC_VERSION = MSVC2022   # Win64 バイナリの MSVC バージョン
```

**注意**: ICU_MSVC_VERSION は ICU リリースで提供されているバイナリに合わせてください。
利用可能なバージョンは https://github.com/unicode-org/icu/releases で確認できます。
(例: MSVC2019, MSVC20222 等)

## 前提環境

- MSYS2 (または Git Bash 等)
- make
- objcopy (MSYS2 の binutils に含まれる)
- ar (MSYS2 の binutils に含まれる)
- Python 3 (`py -3` コマンドで起動可能なこと)
- curl または wget (自動ダウンロード用)
- unzip (自動ダウンロード用)

**注意**: Python の追加モジュール (hjson 等) は `build/icudata/venv/` に
自動的にインストールされます。

## ビルド方法

本ディレクトリで make を実行してください。
icudata のファイルと、MSYS2 の `objcopy` と `ar` を使用して静的ライブラリを作成します。

```bash
cd icudata

# 静的ライブラリを作成 (デフォルト: 64bit)
make
```

出力先: `build/icudata/lib/libicudt77.a`

### アーキテクチャ変更

デフォルトは 64bit です。32bit 用にビルドする場合は以下のように指定します:

```bash
# 32bit Windows
make OBJFORMAT=pe-i386 OBJARCH=i386 ADD_UNDERSCORE=1
# 64bit Linux
make OBJFORMAT=elf64-x86-64 OBJARCH=i386:x86-64
# 32bit Linux
make OBJFORMAT=elf32-i386 OBJARCH=i386 ADD_UNDERSCORE=1
```

### その他のコマンド

```bash
# ICU データのダウンロードのみ
make prepare

# .dat ファイルのみ作成
make datfile

# クリーン (中間ファイルのみ)
make clean

# クリーン (生成した lib のみ)
make clean-lib

# 全てクリーン (ダウンロードデータ含む)
make clean-all
```

基本的には `filters.json` を変更した場合のみ再ビルドすれば OK です。

## リソースのフィルタリング指定

filters.json で、何をリソースとして含むかをフィルタリング指定可能です。
具体的には以下のドキュメントを参照してください。

https://github.com/unicode-org/icu/blob/master/docs/userguide/icu_data/buildtool.md

minikin としては brkitr は使う予定のロケール分は必要。
あとは、フォント絡みでもロケールタグ関係で必要になるので misc と
もしかしたら他にもなにか必要になるかもしれません。

## 既知の問題

ICU77.1（78も）

brkitr_adaboost 用のデータを作るために genrb というツールで以下のファイルを処理しているが、
このファイルを読み込む際に UTF-8 が誤認される。genrb 側のバグだと思われる（バイナリでファイルを開いてないと思われる）
先頭に BOM をつけると回避できるので、download_icu_data.sh に、追加用の処理が入っている。

/data/brkitr/adaboost/jaml.txt

