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

### 外部ライブラリ

freetype は vcpkg.json で導入して find_package() できるものを使います

icu は指定バージョンのものを DL して、harfbuzz で使う部分だけ icucommon としてビルドしています。
icu のデータについては、icudata フォルダ以下の処理で作成して icudata としてライブラリリンクできるようになっています。

※オプション ICU_USE_STUBDATA を指定して作成した場合は icucommon に含まれるデータは空のスタブになり icudata は生成されません
別途  udata_setCommonData() で自前ロードする形になります

harfbuzz は前述の手順で組み込まれる freetype と icu を組み込んだ形で cmake でビルドされます
minikin はこの harfbuzz を使ってフォント情報取得と改行位置決定処理を行っています

### ビルド手順

環境別のビルドは CMakePresets.json の定義に合わせて --preset 指定で対応して下さい

ビルド用の Makefile が準備されています。以下の手順でビルドできます

```bash
make prebuild
make
```

### LICENSE

MINIKIN    Apache License 2.0
freetype   FreeType License（FTL）
ICU        ICU License
HarfBuzz   MIT

