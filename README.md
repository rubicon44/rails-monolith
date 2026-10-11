# README
## このプロジェクトの作成目的
- Railsでの「ドメインモデリング・DB設計」の型を、小さな題材で身につけて確立すること

## 得たいもの
- モデリング・DB設計の知見 / 設計書レビューの型 / Fatにしない設計の実践

## 題材とスコープ
- イベント型マッチング（イベント作成 → 申込 → 審査 → 開始 → いいね → 結果発表）。課金は対象外

## 進め方
- 最小限のPoCを作り、フィードバックをもとに段階的に育てる

## 設計方針
### レイアウト（画面の外枠）
- Controllerは「何を返すか」だけを持ち、見た目（どの枠で見せるか）はViewが決める
- Controllerでは `layout` / `render layout:` を使わない
- `layouts/application.html.erb` には、HTMLの骨組み（`<html>` / `<head>` / `<body>`）だけを書く
- View（erb）で共通化したい枠は、`admin/shared/_frame.html.erb` のような共通テンプレートとして作り、各Viewの中で `<%= render layout: "admin/shared/frame" do %> … <% end %>` のように呼び出す
