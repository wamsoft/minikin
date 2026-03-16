# minikin port

Android の minikin を単独のライブラリとして
利用できるようにするためのレポジトリです。

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

### vcpkg の使用

freetype は vcpkg.json で導入されるものを使います



```bash

$ mkdir build
$ cd build
$ cmake .. -DUSE_VCPKG=ON
$ cmake --build .
# あるいはシンプルに minikin.sln を VS2019 で開いてビルド
```

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

