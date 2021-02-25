# About

harfbuzz-icu-freetype の ICU では data を持たないため、
locale 関連の API や BreakIterator がリソースエラーで
動作しない問題を解決するために、data を単独でビルドするために
必要なものを集めたディレクトリです。

また、単純に全リソースをビルドすると巨大になるため、
必要なリソースのみをビルドするようにしてあります。

- harfbuzz-icu-freetype のビルドから stubdata のリンクを外す
- 必要な ICU リソースだけをビルドして static lib として生成する
- minikin + harfbuzz-icu-freetype にリンクする

## タスク

- [ ] Windows 以外の生成に対応
  - ディレクトリ等を考慮して Makefile を更新する必要あり

## Windows 向け以外のビルドについて

現状では、最終的に static lib にする部分が Windows 向けのみとなっています。
`pkgdata.exe` の static lib の生成方法が C ソースに
ハードコードされているせいです。

ただ、単純にパックしたバイナリデータにエントリポイントのシンボルを
つけてアーカイブしただけのように見えるので、objdump 等のバイナリツールで
シンボルをつけてオブジェクト化したらいけるのではないかなあと。

## 各ファイル・ディレクトリの由来

**_[重要] `data/` と `bin/` は harfbuzz-icu-freetype 内の ICU の
バージョンアップに合わせて適切なバージョンに更新してください
(ICU 内部のリソースバンドルの読み込み部でバージョン番号を
エントリポイント名に使用しているので合わせないと多分コケます)。_**

以下、ファイル名にバージョン番号が含まれる場合は、適切に読み替えてください。

- data/
  - ICU のソースのうち、`icu4c/source/data/` のみを抜き出したもの
  - 公式でアーカイブして配布しているのでそれを配置
    - icu4c-67_1-data.zip
    - https://github.com/unicode-org/icu/releases
- bin/, bin64/
  - ICU の tools バイナリ群
  - なるべく `data/` とバージョンを揃えたほうが良いと思われる
  - 公式アーカイブ内の `bin/` もしくは `bin64/`以下を配置
    - icu4c-67_1-Win32-MSVC2017.zip
    - icu4c-67_1-Win64-MSVC2017.zip
    - https://github.com/unicode-org/icu/releases
- icutools/
  - ICU のソースのうち、`icu4c/source/python/icutools` のみを抜き出したもの
  - なるべく `data/` とバージョンを揃えたほうが良いと思われる
  - 個別アーカイブはないので、ソースツリーから個別コピー
    - icu4c-67_1-src.zip
    - https://github.com/unicode-org/icu/releases
      - github 上では以下のツリー
      - https://github.com/unicode-org/icu/tree/release-67-1/icu4c/source/python/icutools
- harfbuzz-icu-freetype_cmake.patch
  - harfbuzz-icu-freetype の CMakeLists.txt で stubdata.cpp をターゲットから
    外すためのパッチです。
  - シンプルなので直接エディタで編集しちゃうのでも問題なし

## 前提環境

MSYS + make + python3 を想定(それでのみ確認)。

## ビルド方法

本ディレクトリで、make を実行してください。
`lib32/` および `lib64/` にリソースバンドルの static lib が生成されます。

基本的には `filters.json` を変更した場合のみ再ビルドすれば OK です。

## リソースのフィルタリング指定

filters.json で、何をリソースとして含むかをフィルタリング指定可能です。
具体的には以下のドキュメントを参照してください。

https://github.com/unicode-org/icu/blob/master/docs/userguide/icu_data/buildtool.md

minikin としては brkitr は使う予定のロケール分は必要。
あとは、フォント絡みでもロケールタグ関係で必要になるので misc と
もしかしたら他にもなにか必要になるかもしれません。

### リソースバンドルのファイルからのロード

ICU 標準でファイルからのロードという方法もあるようなのですが、
ファイルロード周りを仮想化している雰囲気が無く、fopen とかが
そのまま埋まってる気配があるので PS4/5 などへの展開を考えると
ちょっと難しそうな感じはします。

とはいえ、staic lib でリンクするにしても pkgdata.exe を解析して
相当の処理を自前で用意しないといけないのですが。
