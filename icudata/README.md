# About

ICU 用のリソースデータの単独でのビルドに
必要なファイル等を集めたディレクトリです。

また、単純に全リソースをビルドすると巨大になりますが、
フィルタ指定により必要なリソースのみをビルドすることが
可能になっています(方法は後述)。

## 仕組みの概要 (重要)

ビルド済みの ICU データパッケージ (.dat) を **gzip 圧縮してこのディレクトリに
同梱** しています (`icudt77l.dat.gz`)。

通常のビルドでは、この `.dat.gz` を Python (`gen_icudata_c.py`) で解凍しつつ
C ソース (ICU エントリポイントシンボル `icudt77_dat` を定義する 16 バイト
整列配列) に変換し、上位の `CMakeLists.txt` がそれをそのプロジェクトの
コンパイラで直接コンパイル・リンクします。

このため通常ビルドには:

- **Python 3 だけあればよい** (追加モジュール不要)
- ICU ネイティブツール (bin64 等) のダウンロードも、`make`、`objcopy`、`ar` も不要
- `git clone` 一発で、Windows / Linux / macOS いずれでもそのままビルドできる

ICU データそのものを作り直す (= `.dat.gz` を更新する) のは、`filters.json` や
ICU バージョンを変更したときだけで、その際は ICU ツールが入手できるホスト
(Windows / Linux-x64) で `make update-bundle` を実行します (後述)。

## ディレクトリ構成

```
icudata/
├── Makefile              # データ再ビルド / C ソース生成用 Makefile
├── README.md             # このファイル
├── filters.json          # リソースフィルタ設定
├── download_icu_data.sh  # ICU データ/ツールのダウンロードスクリプト
├── gen_icudata_c.py      # .dat(.gz) → C ソース変換スクリプト
├── icudt77l.dat.gz       # 同梱: gzip 圧縮済み ICU データ (これがビルドの入力)
└── requirements.txt      # Python 依存モジュール (データ再ビルド時のみ使用)

../build/icudata/         # データ再ビルド時の出力先 (自動生成、update-bundle 時のみ)
├── data/                 # ICU データソース (GitHub からダウンロード)
├── bin64/                # Win64 ツールバイナリ (GitHub からダウンロード)
├── icutools/             # Python ツール (GitHub からダウンロード)
├── venv/                 # Python venv 環境 (hjson 等インストール済み)
└── icudata_build/
    ├── out/              # ビルド中間ファイル (.res 等)
    ├── tmp/              # 一時ファイル
    ├── dat/              # .dat パッケージファイル
    └── csrc/             # .dat(.gz) を埋め込んだ生成 C ソース
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

### 通常ビルド (同梱 .dat.gz を使う場合)

- **Python 3 のみ** (Windows は `py -3`、それ以外は `python3` で起動可能なこと)

これだけです。`objcopy` / `ar` / `make` / ICU ネイティブツールは不要で、
出力フォーマットやアーキテクチャ・アンダースコアの指定も要りません。
Windows / Linux / macOS で同一手順で動作します
(GNU objcopy が mach-o を生成できない問題も解消)。

通常は上位の `CMakeLists.txt` が、ビルド時に同梱 `icudt77l.dat.gz` を
`gen_icudata_c.py` で解凍・C ソース化し、`icudata` 静的ライブラリとして
コンパイル・リンクするため、**このディレクトリで手動操作は不要**です。

### .dat.gz を更新する場合のみ

`filters.json` や ICU バージョンを変えて `.dat` を作り直すときだけ、以下が
追加で必要です (「同梱データの更新」を参照):

- MSYS2 (または Git Bash 等) / make
- curl または wget、unzip (ICU データ・ツールの自動ダウンロード用)
- ICU ネイティブツールが入手できるホスト (Windows / Linux-x64)

**注意**: Python の追加モジュール (hjson 等) は `build/icudata/venv/` に
自動的にインストールされます。

## ビルド方法 (単体)

通常は上位 CMake から自動で行われますが、このディレクトリ単体で C ソースを
生成することもできます。同梱 `.dat.gz` を解凍して C ソースを出力します
(Python のみ。ICU ツール不要)。

```bash
cd icudata
make            # = make csource
```

出力先: `build/icudata/icudata_build/csrc/icudt77_dat.c`

この `.c` には ICU エントリポイントシンボル `icudt77_dat` が定義されており、
16 バイト境界に整列した、先頭がデータ先頭バイトの配列になっています
(ICU の `common/udata.cpp` がこのシンボルを `DataHeader` として読みます)。

## 同梱データ (.dat.gz) の更新

`filters.json` を変更したり ICU バージョンを上げたりして ICU データを
作り直す場合は、ICU ネイティブツールが入手できるホストで `.dat` を
ビルドし直し、同梱の `.dat.gz` を更新してコミットします。

**対応ホスト**: 現状 `download_icu_data.sh` がダウンロードするのは
**Windows 用 (Win64 MSVC) ツール**です。したがって `make update-bundle` は
**MSYS2 等を備えた Windows ホスト**で実行してください。

生成される `.dat` は**プラットフォーム非依存 (リトルエンディアン)** なので、
Windows で一度更新すれば、その `.dat.gz` を Linux / macOS を含む全環境で
そのまま使えます。

```bash
cd icudata

# ICU データ・ツールをダウンロードし、.dat を再ビルドして .dat.gz を更新
make update-bundle

# 生成された icudata/icudt77l.dat.gz をコミットする
git add icudt77l.dat.gz && git commit -m "update bundled icudata"
```

> Linux-x64 ホストで更新したい場合は、ICU 公式リリースの
> `icu4c-77_1-Ubuntu22.04-x64.tgz` 等を取得・展開し、`TOOL_DIR` をその
> `bin` に向け、実行時に `LD_LIBRARY_PATH` へ同梱 `lib` を加えるよう
> `download_icu_data.sh` / Makefile を拡張する必要があります
> (macOS / arm64-Linux 向けの公式ビルド済みツールは配布されていません)。

### その他のコマンド

```bash
# ICU データ・ツールのダウンロードのみ
make prepare

# .dat ファイルのみ再ビルド (.dat.gz は更新しない)
make datfile

# クリーン (中間ファイルのみ)
make clean

# クリーン (再ビルドした .dat と生成 C ソース。同梱 .dat.gz は消さない)
make clean-gen

# 全てクリーン (ダウンロードデータ含む)
make clean-all
```

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

