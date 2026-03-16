# minikin port

Android の minikin を単独のライブラリとして(主に Windows で)
利用できるようにするためのレポジトリです。

とりあえずは各種テストを Windows で行えるようにすることを優先しているので、
m2lib 等に組み込む場合は、さらに対応が必要になるはずです。

## fork についてのメモ

オリジナルのソースツリーの fork という形式にしてあるため、
オリジナルのコミットログが全部見える状態になっています。

以下のような形でオリジナルを upstream として取り込みました。

- github で新規レポジトリ(ここ)を作成
- 作ったレポジトリをローカルに clone
- オリジナルのツリーを upstream として設定

```
$ git remote add upstream https://android.googlesource.com/platform/frameworks/minikin
$ git fetch upstream
$ git merge upstream/master
```

- upstream をマージしたものを `wamsoft/minikin` として push

```
$ git push origin master
```

- 以後、単独ビルドのための対応を随時コミット。

## タスク

- [x] minikin 単独でのライブラリビルド
- [x] minikin をリンクしたテスト実行バイナリの作成

## minikin の Windows ビルド対応について

### 主な変更点

- 変更した部分は基本的に `#ifdef WAMSOFT_MODIFIED` でマークしてあります。
- Android core のヘッダ等で「とりあえず現物をコピー配置で対応可能」あるいは
  「ダミー・代替実装を配置して対応する」ケースでは、基本的に `libs/` に配置する。
  詳細は `libs/README.md` を参照
- `log/log.h` については、対応部分が多いこととマクロ/関数の置き換え/無効化の
  範囲が大きいため、`libs/log/log.h` を作成してその中に各種置き換え/ダミーの
  定義・実装を配置してある。
- その他のダミー実装系は `libs/_stub.h` に実装を用意して、CMake のコマンドで
  コンパイラの強制インクルードですべてのファイルが読み込むような形にしてある
  - `ssize_t` など範囲が広く、各ソースで共通して include しているヘッダがないため
    このような対応にした。
  - 強制インクルードの方法はコンパイラ依存なので、最終的に CMake を使用しない
    m2lib などに組み込む際は `#include "_stub.h"` を必要なソースに書いてまわらないとダメかも…。

### vcpkg を使用する

前準備として vcpkg で freetype、harfbuzz、icu を導入しておきます。
注意としては、harfbuzz は icu 対応にする必要があるので、
`vcpkg install harfbuzz[icu]` と指定する必要があります。
(もしかしたら、先に icu が導入済みの場合は勝手に入れてくれるかも？未確認)

CMake に `-DUSE_VCPKG=ON` を渡すことによって、vcpkg を参照した
プロジェクトが生成されます。

```bash
$ mkdir build
$ cd build
$ cmake .. -DUSE_VCPKG=ON
$ cmake --build .
# あるいはシンプルに minikin.sln を VS2019 で開いてビルド
```

### harfbuzz-icu-freetype を使用する

harfbuzz-icu-freetype を使用する場合は、minikin のルート直下に
harfbuzz-icu-freetype を clone しておいてください。

CMake の参照の仕方(`add_subdirectory()`)の関係上、配下に展開する必要があります。

```bash
$ git clone https://github.com/tangrams/harfbuzz-icu-freetype.git
```

clone 後、cmake を実行する前に以下のパッチを適用してください。

harfbuzz-icu-freetype は、データファイルを stub で代用しているため、
BreakIterator やロケール関連の機能をしようとするとエラーになりますが、
それを回避するために stub のリンクを削除するパッチです。

```bash
$ patch -p0 < harfbuzz-icu-freetype_cmake.patch
```

ここで必要なら、ICU のリソースデータを再ビルドしてください。
(含めるロケールを変更するなどした場合)。

```bash
$ cd icudata
$ make
```

その後、通常の CMake でビルド(あるいは、参照先のプロジェクトの
CMake からビルド)を実行してください。

```bash
$ mkdir build
$ cd build
$ cmake ..
$ cmake --build .
# あるいはシンプルに minikin.sln を VS2019 で開いてビルド
```

