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

## ドメインモデル
### ドメインの分け方
- ドメインは、人ではなく業務で分ける
  - 例：いいねを送るのは会員だが、「トークタイム中だけ」「1人だけ」はイベントの進め方のルールなので、イベントドメインに置く
- ルールは「誰の都合で変わるか」で置き場所を決める
  - 例：定員（企画の都合）はイベント、メールの送り方（運用の都合）は通知、パスワードの条件（セキュリティの都合）はログインに置く
- 操作する人や経路を変えても残るルールは、独立したドメインに置く
  - 例：イベントの開始は管理者の手動とバッチの自動の2つの入口があるが、「準備完了からしか開始できない」はどちらでも同じなので `Event` に置く
- 人のドメインには、その人自身のこと（名前、ログインなど）だけを置く
  - 例：会員には名前・性別・ログインを置き、「申し込んだイベント」や「送ったいいね」は会員ではなくイベントドメインに置く
- コアドメインのModelは、サブドメイン（通知、ログインの方式、外部連携など）に依存させない。サブドメインの側がコアに合わせる
  - 例：イベントのModelの中にメール送信を書かない
- Railsにはユースケース層がないため、Controllerが処理の組み立て（ユースケースのオーケストレーション）を担う。サブドメインへの依存は、Modelではなく、ここで許容する
  - 例：Controllerで申込を作ったあと、作った申込を通知用のクラスに渡してメールを送る
  - 同じ組み立てが複数の入口（Controller、バッチ、外部連携など）で必要になったら、POROに切り出す
    - 例：会員画面と外部サービスの両方から申込を受け付けるなら、「申込を作る → 通知する」を `EntryApplication.call(event:, member:)` のようなPOROにまとめ、両方から呼ぶ（受付メールを足すときも1か所を直すだけで済む）
    - Concernにしない理由：Controllerの Concern はControllerからしか使えず、バッチや外部連携から呼べない。Modelの Concern にすると、組み立て（通知）がModelの一部になり、コアがサブドメインに依存してしまう
- 1つの集約は、1つのドメインにだけ属する
  - 例：イベント集約は会員と管理者の両方から使われるが、両方のドメインには入れず、イベントドメインにだけ置く（両方に置くと、定員のチェックが2か所に書かれる）

### 現時点のドメインモデル図（2026/10/13）
https://github.com/user-attachments/assets/ed618838-3649-42b1-8d44-d1f0bf58fd41

## 設計方針
### ControllerとModelの役割
- Controllerには、HTTPやセッションの処理を書く（パラメーターの受け取り、ログインの確認、セッションの操作、`redirect_to` / `render`、flash）
- Modelには、ドメインロジック（制約・ルール）を書く（バリデーション、業務上の判断や計算、状態遷移）
  - 意味的に分けられる処理（例：料金の計算、状態遷移）は積極的にPOROに切り出し、保守性を継続的に高める

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

### Rakeタスク
- Railsの機能（モデルやDB）を使うスクリプトは、カスタムRakeタスクとして `lib/tasks/*.rake` に書く（例：管理者の作成 `admin:create`）
- モデルやDBを使うタスクは、`environment` タスクに依存させる（Railsアプリを読み込むため）
  - 参照：https://guides.rubyonrails.org/command_line.html#custom-rake-tasks
- 引数を受け取るタスクは、Rakeのドキュメントの書き方に合わせる（例：`task :create, [ :name, :email_address ] => [ :environment ] do |_, args|`）
  - 参照：https://ruby.github.io/rake/doc/rakefile_rdoc.html#tasks-that-expect-parameters-and-have-prerequisites

## 進め方のログ
### これまで（2026/10/12）
1. 全体の大枠を決めた：管理者ドメイン／会員ドメイン／イベントドメイン（コアドメイン）
2. 独立した機能から作った：管理者ログイン（汎用サブドメインのため、モデリングは属性と制約だけの浅いもので進めた）
3. 作りながら命名や設計方針を決め、READMEに残した

### これから（2026/10/12 時点）
1. イベントドメイン（コアドメイン）をしっかりモデリングする：状態遷移、集約の範囲、ルール、ユビキタス言語
2. コアが周りのドメインに求めること（例：会員の性別は必須）を確認する
3. モデリングをもとに、イベント作成から順に実装する
4. 実装やフィードバックで分かったことを、モデルに戻して育てる
