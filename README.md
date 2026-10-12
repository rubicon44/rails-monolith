# README
## このプロジェクトの作成目的
- Railsでの「ドメインモデリング・DB設計」の型を、小さな題材で身につけて確立すること

## 得たいもの
- モデリング・DB設計の知見 / 設計書レビューの型 / Fatにしない設計の実践

## 題材とスコープ
- イベント型マッチング（イベント作成 → 申込 → 審査 → 開始 → いいね → 結果発表）。課金は対象外

## 進め方
- 最小限のPoCを作り、フィードバックをもとに段階的に育てる

## 先回りして決めたこと
サービスの成長に伴って起きやすい問題を、最初からルールで防ぐ。

| 先に決めたこと | サービスの成長に伴って起きやすいこと |
| --- | --- |
| レイアウトはViewで決め、Controllerでは指定しない | どこでレイアウトが決まっているのか分からなくなる |
| ロジックの置き場所を、ドメインモデリングで先に決める | 新しい機能が、中心のモデルに直接足され、Fat化が止まらない |
| （予定）状態遷移はモデルの1か所に集める（イベント機能で実践予定） | 状態遷移が複数のControllerやバッチにコピーされ、直し漏れが起きる |
| 画面の領域の名前とモデルの名前を分ける | 名前の衝突や、言葉の取り違えが起きる |
| 書き方はRuboCopに従う | 書き方がばらつき、レビューで迷う |

## 設計方針
### インスタンス変数
Controllerでインスタンス変数を使ってよいのは、インスタンス変数を使ったメモ化（memoization）の場合だけ。Viewへの受け渡し、`before_action` からの値の受け渡し、アクションの中での一時的な値には使わない。

| 用途 | 使うもの |
| --- | --- |
| メソッドの結果を覚えておく（インスタンス変数を使ったメモ化） | `@xxx \|\|= …`（例：`@current_administrator \|\|= Administrator.find_by(…)`） |
| Viewに値を渡す | `render locals:` |
| `before_action` で用意していた値 | 値を返すprivateメソッド |
| Controllerのアクションの中で一時的に使う値 | ローカル変数 |

- メモ化のためのインスタンス変数は、外から直接使わず、メソッドを呼ぶ
  - 例：Viewでは `@current_administrator` ではなく `current_administrator` を呼ぶ（`helper_method` で公開する）
  - 理由：インスタンス変数は、メソッドが先に呼ばれていないと `nil` のままで、エラーにもならず気づきにくいため
- Viewで使う値は、Controllerのインスタンス変数ではなく `render locals:` で渡す
  - 例：`render locals: { event: event }`、失敗時は `render :new, locals: { event: event }, status: :unprocessable_entity`
  - 理由：インスタンス変数はController内のどこからでも書き換えられ、値の出どころを追いにくいため
- Viewの先頭で、strict locals（Rails 7.1〜）を使って受け取る値を宣言する（例：`<%# locals: (event:) -%>`）
  - 理由：渡し忘れや名前の間違いを、描画を始めた時点でエラーにするため
  - 受け取る値がないView・パーシャルでも、`<%# locals: () -%>` と宣言する（例：`admin/shared/_frame.html.erb`、`admin/dashboards/show.html.erb`）
    - 理由：「何も受け取らない」のか「宣言を書き忘れた」のかを区別し、うっかり値を渡したときもエラーにするため
  - View内の strict locals の宣言では、初期値を決めない（`<%# locals: (email_address: nil) -%>` のようにしない）。値がない場合は、Controllerから `nil` を明示的に渡す
    - 例：ログイン画面を初めて開いたときは `render locals: { email_address: nil }`
    - 理由：初期値があると、渡し忘れてもエラーにならず初期値のまま表示されるため、渡し忘れに気づけなくなるため
  - 参照：https://guides.rubyonrails.org/action_view_overview.html#strict-locals
- `before_action` でインスタンス変数に値を入れない。必要な値は、値を返すprivateメソッドにする
- Controllerのアクションの中で一時的に使う値は、インスタンス変数ではなくローカル変数にする
  - 理由：Controllerのインスタンス変数は、使うつもりがなくても自動でViewに渡り、Viewから使えてしまうため

### レイアウト（画面の外枠）
- Controllerは「何を返すか」だけを持ち、見た目（どの枠で見せるか）はViewが決める
- Controllerでは `layout` / `render layout:` を使わない
- `layouts/application.html.erb` には、HTMLの骨組み（`<html>` / `<head>` / `<body>`）だけを書く
- View（erb）で共通化したい枠は、`admin/shared/_frame.html.erb` のような共通テンプレートとして作り、各Viewの中でパーシャルレイアウト（partial layouts）を使って `<%= render layout: "admin/shared/frame" do %> … <% end %>` のように呼び出す
  - 参照：https://guides.rubyonrails.org/layouts_and_rendering.html#partial-layouts

### フォーム（ログイン）
- メールアドレスの入力欄は `type="email"`（`email_field`）にしたうえで、`autocomplete="username"` を指定する（`email` ではなく `username`）
  - 理由：`username` は、最新のブラウザのパスワードマネージャーに認識されるため
- パスワードの入力欄は `autocomplete="current-password"` を指定する
  - 理由：そのサイト用に保存されている現在のパスワードを使うよう、ブラウザに伝えるため
- `id` は、Railsのフォームヘルパーが作るもの（例：`email_address`、`password`）のままにする。参照先にある `id="email"` や `id="current-password"` には合わせない
  - 理由：参照先でも `id` は補助的な扱いで、`autocomplete` を指定していれば認識されるため。
- 参照：https://web.dev/articles/sign-in-form-best-practices
