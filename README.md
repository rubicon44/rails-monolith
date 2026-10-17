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

## ドメインモデリング
### 目的
- ドメインに分けること自体が目的ではなく、変更しやすい単位にすること（変更容易性を高めること）が目的
- 一緒に変わるものは一緒に置き、別々に変わるものは分ける
- 迷ったら、次の2つで考える
  - よく起きる業務の変更が来たとき、直す範囲が1つの単位（ドメインやモデル）に収まるか
  - その単位が、関係のない理由（別の業務の変更、通知の方式の変更など）で変更されないか

### ユビキタス言語（用語集）
会話・設計書・コードで同じ言葉を使う。画面の領域の名前と、モデルの名前は分ける。

| 用語 | 定義 | コード上の名前 | 使わない言葉 |
| --- | --- | --- | --- |
| 会員 | イベントに申し込み、参加する人 | `Member` / `members` | ユーザー（画面の領域の名前と混ざるため） |
| 管理者 | イベントを作成・運営する人 | `Administrator` / `administrators` | Admin（画面の領域の名前と混ざるため） |
| ユーザー画面 | 会員が使う画面の領域 | `User::`、`/` | — |
| 管理画面 | 管理者が使う画面の領域 | `Admin::`、`/admin` | — |
| イベント | 管理者が開催し、会員が申し込んで参加する催し | `Event` / `events` | パーティー |
| 定員 | イベントに参加できる人数の上限。男性と女性で別々に決める | `male_capacity` / `female_capacity` | — |
| 申込期間 | 会員がイベントに申し込める期間 | `entry_start_at` 〜 `entry_end_at` | — |
| 開催期間 | イベントを開催する期間 | `held_start_at` 〜 `held_end_at` | — |
| 進行状態 | イベントがどの段階にあるか（開催前、準備完了、開始…） | `status` | — |
| 作成者 | イベントを作成した管理者 | `administrator`（`administrator_id`） | — |

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

### パラメーターの受け取り
- フォームの送信など、必ず送られてくるパラメーターは `params.expect` で受け取る（`require(...).permit(...)` は使わない）
  - 例：`params.expect(event: [ :title, :description ])`
  - 理由：想定外の形のリクエスト（例：ハッシュのはずの `event` に文字列が送られてくる）を、500エラーではなく400エラーにするため
  - 参照：https://api.rubyonrails.org/classes/ActionController/Parameters.html#method-i-expect
  - 参照：https://guides.rubyonrails.org/action_controller_overview.html#strong-parameters
- 検索条件など、送られてこないこともあるパラメーターは、`params.fetch(:キー, {}).permit(...)` で受け取る
  - 例：`params.fetch(:q, {}).permit(:keyword, :status)`
  - 理由：`expect` はキーがないと400エラーになるため。キーがないときは `fetch` で空のハッシュを初期値にする
  - 参照：https://guides.rubyonrails.org/action_controller_overview.html#strong-parameters

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

### フォーム（form_with）
レコードを作る・更新するフォームは `form_with model:`、それ以外のフォームは `form_with url:` を使う。

| | `form_with model:` | `form_with url:` |
| --- | --- | --- |
| 使う場面 | レコードを作る・更新する（例：イベントの作成・編集） | レコードを作らない・更新しない（例：ログイン、検索） |
| 渡すもの | 作成：`Event.new`（新しいオブジェクト）<br>編集：`Event.find(params[:id])`（保存済みのオブジェクト） | 送信先のURL（例：`admin_login_path`） |
| 送信先 | 渡したオブジェクトから自動で決まる（新しいなら `POST /admin/events`、保存済みなら `PATCH /admin/events/1`） | 渡したURL |
| 入力欄の名前 | モデル名でまとめられる（`event[title]`） | そのまま（`email_address`） |
| 入力欄の初期値 | オブジェクトの値が自動で入る | 自分で `value:` を指定する |
| Controllerでの受け取り方 | `params.expect(event: [ :title, … ])` | `params[:email_address]` |

- 参照（`form_with` の `model:` と `url:` を含む、すべてのオプション）：https://api.rubyonrails.org/classes/ActionView/Helpers/FormHelper.html#method-i-form_with

#### 共通：入力欄の名前と `params` の関係
- 入力欄を作るヘルパー（`form.text_field`、`form.search_field` など）の最初の引数が、入力欄の名前（`name`）になる
- フォームを送信すると、その名前が `params` のキーになり、Controllerで値を受け取れる
- `form.label` の最初の引数は、どの入力欄のラベルかを示すだけ（`for` 属性）で、値は送信されない
- 参照（入力欄の名前と `params` の形の関係）：https://guides.rubyonrails.org/form_helpers.html#form-input-naming-conventions-and-params-hash

#### `form_with url:` の受け取り方
- 入力欄の名前が、そのまま `params` のキーになる
  - 例：`form.email_field :email_address` → `<input name="email_address">` → Controllerで `params[:email_address]`
- 参照（`form_with url:` を使った検索フォームの例）：https://guides.rubyonrails.org/form_helpers.html#a-generic-search-form
- 参照（入力欄の名前が `params` のキーになり、`params[:query]` で受け取れる）：https://guides.rubyonrails.org/form_helpers.html#helpers-for-generating-form-elements

#### `form_with model:` の受け取り方
- 入力欄の名前が、モデル名でまとめられる。Controllerでは、モデル名のキーの中に、すべての値がハッシュで入る
  - 例：`form.text_field :title` → `<input name="event[title]">` → Controllerで `params[:event][:title]`（まとめて `params.expect(event: [ :title, … ])` で受け取る）
- `new` の `Event.new` と `create` の `Event.new` は別物。`new` のものは空のフォームを表示するためだけに使い、`create` には引き継がれない（`create` に届くのはフォームの値だけ）
- 保存に失敗したら、入力された値とエラーを持ったオブジェクトをそのまま渡して、同じ画面を再表示する
- ルーティングは `resources` で書く（送信先を自動で決める仕組みは、`resources` で宣言されていることが前提のため）
- 参照（`form_with model:` にオブジェクトを渡すと、入力欄の名前が `book[...]` でまとめられ、`params[:book]` で受け取れる）：https://guides.rubyonrails.org/form_helpers.html#binding-a-form-to-an-object
- 参照（新しいオブジェクトか保存済みかで送信先が変わる。`resources` で宣言されていることが前提）：https://guides.rubyonrails.org/form_helpers.html#relying-on-record-identification
- 参照（`new` アクションで新しいオブジェクトを作るのは、フォームを表示するため）：https://guides.rubyonrails.org/getting_started.html#creating-products
- 参照（`params.expect` でのパラメーターの受け取り方）：https://guides.rubyonrails.org/action_controller_overview.html#strong-parameters

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
