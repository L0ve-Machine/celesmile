# 本番リリース準備 TODO

## 完了済み
- [x] Stripe APIキーを本番用に切り替え
- [x] JWT_SECRETを強力なランダム文字列に変更
- [x] DBパスワードのハードコードを環境変数に修正
- [x] Celestcare → Celesmile の表記修正
- [x] 広告バナー機能追加
- [x] 広告バナー設定方法ドキュメント作成

## 未完了（ローカルPCで実行）

### 1. アプリアイコン生成
```bash
git pull
flutter pub get
flutter pub run flutter_launcher_icons
git add .
git commit -m "Generate app icons from logo.png"
git push
```

## 未完了（VPSで実行）

### 2. APIサーバー再起動
```bash
# .envの変更を反映するため再起動が必要
cd /root/celesmile/api
# 実行中のサーバーを停止して再起動
```

---
作業完了後、このファイルは削除してOK
