# アプリアイコン生成手順

## 現状の問題
- Android/iOS のアプリアイコンがFlutterデフォルトロゴのまま
- `flutter_launcher_icons` の設定は完了しているが、コマンドが未実行

## ローカルPCで実行すること

```bash
# 1. 最新のコードを取得
git pull

# 2. 依存関係を取得
flutter pub get

# 3. アイコン生成を実行
flutter pub run flutter_launcher_icons

# 4. 生成されたアイコンをコミット＆プッシュ
git add .
git commit -m "Generate app icons from logo.png"
git push
```

## 確認事項
- 実行後、以下のフォルダにlogo.pngベースのアイコンが生成される
  - Android: `android/app/src/main/res/mipmap-*/`
  - iOS: `ios/Runner/Assets.xcassets/AppIcon.appiconset/`

## 設定内容（pubspec.yaml）
```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/images/logo.png"
  adaptive_icon_background: "#FFFACD"
  adaptive_icon_foreground: "assets/images/logo.png"
```

---
このファイルは作業完了後に削除してOK
