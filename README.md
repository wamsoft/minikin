# minikin port

Android の minikin を単独のライブラリとして(主に Windows で)
利用できるようにするためのレポジトリ。

とりあえずは各種テストを Windows で行えるようにすることを優先しているので、
m2lib 等に組み込む場合は、さらに対応が必要になるはず。

## タスク

- [x] minikin 単独でのライブラリビルド
- [ ] minikin をリンクしたテスト実行バイナリの作成
- [ ] vcpkg ビルドでフル static リンク
- [ ] CMake を使わない Makefile の作成(m2lib 前提になるので、このレポジトリでは不要か)

## minikin の Windows ビルド対応について

- 変更した部分は基本的に `#ifdef WAMSOFT_MODIFIED` でマークしてある。
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

## ビルド方法

### vcpkg を使用する

前準備として vcpkg で freetype、harfbuzz、icu を導入しておく。
注意としては、harfbuzz は icu 対応にする必要があるので、
`vcpkg install harfbuzz[icu]` と指定する必要がある。
(もしかしたら、先に icu が導入済みの場合は勝手に入れてくれるかも？未確認)

CMake に `-DUSE_VCPKG=ON` を渡すことによって、vcpkg を参照した
プロジェクトが生成される。

```bash
$ mkdir build
$ cd build
$ cmake .. -DUSE_VCPKG=ON
$ cmake --build .
# あるいはシンプルに minikin.sln を VS2019 で開いてビルド
```

### harfbuzz-icu-freetype を使用する

harfbuzz-icu-freetype を使用する場合は、minikin のルート直下に
harfbuzz-icu-freetype を clone しておく。

CMake の参照の仕方(`add_subdirectory()`)の関係上、配下に展開する必要がある。
並列に置いて参照する方法はまだ調べてないが、最終的に CMake を使わない環境(m2lib)での
利用を想定しているので、CMake ビルドではとりあえずこれで確認だけできればいいかなという状態。

```bash
$ git clone https://github.com/tangrams/harfbuzz-icu-freetype.git
$ mkdir build
$ cd build
$ cmake ..
$ cmake --build .
# あるいはシンプルに minikin.sln を VS2019 で開いてビルド
```
