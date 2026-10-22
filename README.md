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

- ドメインの言葉（用語集に載っているモデル名・属性名・enum の値）は、`config/locales/ja.yml` で管理し、画面では必ず ja.yml から取り出して表示する（View に直接書かない）
  - モデル名：`Event.model_name.human` → イベント
  - 属性名：`Event.human_attribute_name(:title)` → タイトル
  - enum の値：`Event.human_attribute_name("status.#{event.status}")` → 開催前
  - 理由：用語集と画面の言葉を1か所でそろえ、言葉を変えるときに ja.yml だけを直せば済むようにするため。属性名を ja.yml に書くと、エラーメッセージの項目名も同じ言葉になる
  - `config/locales` にある `.yml` と `.rb` のファイルは、Railsが自動で読み込むので、`config/locales/ja.yml` を読み込ませる設定は不要
    - 参照（`config/locales` のファイルが自動で読み込まれること）：https://guides.rubyonrails.org/i18n.html#configuring-the-load-paths-and-default-locale
  - ただし、標準の言語は英語（`:en`）なので、日本語の訳を使うには `config/application.rb` に `config.i18n.default_locale = :ja` の設定が必要（設定済み）
    - `config/locales/ja.yml` は設定に関係なく読み込まれるが、訳を探すときに使われるのは今の言語（`I18n.locale`）の訳だけ。`default_locale` を `:ja` にすることで、ja.yml の `ja:` の下の訳が使われるようになる（`:en` のままだと、`Event.human_attribute_name(:title)` は英語の「Title」を返す）
    - 参照（`I18n.locale` の初期値は `I18n.default_locale` で、その初期値は `:en`。言語を指定しないと `I18n.locale` が使われる）：https://guides.rubyonrails.org/i18n.html#setting-and-passing-a-locale
    - 参照（`I18n.locale=` などで変えない限り、すべての訳に標準の言語が使われる）：https://guides.rubyonrails.org/i18n.html#managing-the-locale-across-requests
- 画面だけの言葉（ボタン、メッセージ、見出しなど、用語集に載っていない言葉）は、View に直接書いてよい
- 新しい用語を追加するときは、先にこのREADMEの「ユビキタス言語（用語集）」の表に追加し、同じ言葉を `config/locales/ja.yml` に書く（このREADMEの表が正、ja.yml はそれに合わせる）
  - 各機能の設計書の用語集は、その時点の記録。プロジェクトの用語の正は、このREADMEの表
- 参照（`model_name.human` と `human_attribute_name` で、ja.yml からモデル名・属性名を取り出す方法）：https://guides.rubyonrails.org/i18n.html#active-record-models

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

### ドメインモデル図
#### 2026/10/19
https://github.com/user-attachments/assets/31a59c13-1f48-40fd-91a9-c2d0002767a2

#### 2026/10/13
https://github.com/user-attachments/assets/ed618838-3649-42b1-8d44-d1f0bf58fd41

## 設計方針
### ControllerとModelの役割
- Controllerには、HTTPやセッションの処理を書く（パラメーターの受け取り、ログインの確認、セッションの操作、`redirect_to` / `render`、flash）
- Modelには、ドメインロジック（制約・ルール）を書く（バリデーション、業務上の判断や計算、状態遷移）
  - 意味的に分けられる処理（例：料金の計算、状態遷移）は積極的にPOROに切り出し、保守性を継続的に高める

### クラスメソッドとインスタンスメソッド
メソッドの置き場所は、次の順で決める。
1. どのモデルに置くか：インスタンスメソッドかクラスメソッドかに関係なく、ドメインモデリングで決めた「このルールは誰のものか」で、そのルールを持つモデルに置く。置くモデルを間違えると、モデリングで決めた境界がコードで崩れる
   - インスタンスメソッドの例：「申し込めるか」はイベントのルール → `event.can_accept?(member)`。会員に `member.can_apply_to?(event)` と置くと、イベントのルールが会員に入り込む
   - クラスメソッドの例：「受付中のイベントの一覧」はイベントのルール → `Event.accepting_entries`。会員に `Member.accepting_events` と置くと、受付中の条件が会員に入り込む
2. インスタンスメソッドか、クラスメソッドか：そのモデルの中で、1件のデータを使う処理ならインスタンスメソッド、特定の1件ではない処理ならクラスメソッドにする（下の表とルール）

| | クラスメソッド | インスタンスメソッド |
| --- | --- | --- |
| 何に対する処理か | 特定の1件ではない処理（インスタンスを作る、テーブル全体から探す・数える） | 1件のデータを使う処理（その1件を確かめる、変える、保存する） |
| 定義の仕方 | `def self.メソッド名` または `scope` | `def メソッド名` |
| 呼び方 | `Event.new`、`Event.find(1)`、`Event.order(…)`、`Event.accepting_entries` | `event.save`、`event.valid?`、`event.accepting_entries?` |

- 特定の1件ではない処理（作る、探す、数える）は、クラスメソッドにする
  - 例：受付中のイベントの一覧は `scope :accepting_entries`、1件が受付中かは `def accepting_entries?`
  - 理由：インスタンスメソッドは、1件のインスタンスがないと呼べないため
    - 作る：まだ1件もないのに、作るためのメソッドを呼ぶには、先に1件が必要になってしまう
    - 探す・数える：テーブル全体が対象なのに、関係のない1件を作ってから呼ぶことになる（例：`Event.new.find(1)`、`Event.new.count` のような形になる）
- 1件のデータを使う処理は、インスタンスメソッドにする（クラスメソッドに、1件を引数で渡す形にしない）
  - 良い例：`event.accepting_entries?`（イベント本人に「受付中か」を聞く）
  - 悪い例：`Event.accepting_entries?(event)`（クラスに、イベントのデータを渡して判定させる）
  - 理由：データと、そのデータを使う処理を1つのオブジェクトにまとめるため。クラスメソッドで「データを受け取って処理する」形にすると、データさえ手に入ればどこでも同じ判定が書けてしまい、ヘルパー・API・バッチなどに判定がコピーされていく。判定の条件が変わったとき（例：受付の一時停止を追加する）、すべてを探して直す必要が出る
- 実際にあった例：料金の計算で、上の悪い例と同じ「データを外から受け取って処理する」形になっていた
  - 形：料金を計算するクラスを、計算に必要なデータを全部引数で渡して使っていた（例：`Price.new(party, gender, logged_in, entry_count, coupon)`）。計算する側は自分ではデータを持たず、イベント（パーティー）にも料金を聞く入口がなかった
  - 起きたこと：呼び出し側が「性別をどこから取るか（会員情報かCookieか）」「参加回数を数えるか」「クーポンを渡すか」をそれぞれ自分で決めていた。つまり、データを組み立てる処理（料金のルールの一部）が、パーティーのモデル自身の中での10通り以上の呼び分け（場面ごとに違うデータを組み立てて料金の計算クラスに渡していた）、表示用のクラス、APIなどに散らばった
  - 結果：画面やAPIごとに渡すデータが少しずつ違い、表示の金額と請求額がずれるリスクにつながった。料金のルールを1つ変えるたびに、散らばった呼び出し側をすべて探して揃える必要があった
  - すべきだった形：イベント（パーティー）に料金を聞くインスタンスメソッドを入口にし（例：`party.price_for(member, coupon: coupon)`）、呼び出し側は「誰の料金か」だけを渡す。計算に必要なデータは、計算する側が自分で集める
- ただし、「データを外から受け取って処理する」こと自体が悪いわけではない。問題になるのは、その対象自身のルールを、外で、呼び出し側が組み立てたデータで処理すること
  - 見分け方：「その処理は、誰のルールか」で判断する。受け取る対象自身のルールなら、対象のインスタンスメソッドを入口にする。別の関心ごとのルールなら、別のクラスが対象を受け取って処理してよい

    | | OKな形 | NGな形 |
    | --- | --- | --- |
    | 処理しているのは | 別の関心ごと（編集履歴、通知、CSV出力など） | その対象自身のルール（パーティーの料金、イベントの受付中の判定など） |
    | 受け取るもの | 対象のオブジェクトそのもの（`party`） | 呼び出し側が組み立てたバラバラのデータ（性別、ログイン状態、参加回数など） |
    | 必要なデータを集めるのは | 処理する側が、受け取ったオブジェクトから自分で集める | 呼び出し側がそれぞれ集める |
    | 入口 | 1つ | 呼び出し側ごとにバラバラ |

  - OKな例：編集履歴を残す処理が、パーティーを受け取って、編集前と編集後の状態を記録する。「何を記録するか」は編集履歴のルールで、パーティーのルールではない。記録に必要な値は編集履歴の側が自分で集め、内部の処理は `private_constant` で隠して、入口を1つにしている
  - OKな形でも、依存関係には気をつける
    - 向きは「別の関心ごと → 対象」の一方向にする（例：編集履歴はパーティーを知っているが、パーティーは編集履歴を知らない。パーティーのModelの中で編集履歴を作らず、Controllerから呼ぶ）
    - 対象の中身（カラム）を直接たくさん読むより、公開されたメソッドを使う（対象のカラムが変わるたびに、受け取る側も直すことにならないように）
    - 対象のルールを、受け取った側で作り直さない（例：編集履歴の中で受付中かを自分で計算せず、`party.accepting_entries?` を呼ぶ）
- 参照（検索の条件をクラスメソッドとして定義する `scope`。`def self.` で定義したクラスメソッドとほぼ同じ）：https://guides.rubyonrails.org/active_record_querying.html#passing-in-arguments

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

### パスワードの長さ
- パスワードだけでログインする場合は、最小15文字にする（例：会員のログイン）
  - 理由：NIST SP 800-63B-4 で、パスワードだけでログインする場合は、最小15文字にしなければならない（SHALL）とされているため
  - 参照（パスワードだけでログインする場合は最小15文字、二段階認証の一部として使う場合は最小8文字）：https://pages.nist.gov/800-63-4/sp800-63b.html
- 二段階認証を入れた場合は、最小8文字まで短くしてよい
  - 理由：同じ NIST SP 800-63B-4 で、二段階認証の一部として使うパスワードは、短くしてよいが最小8文字にしなければならない（SHALL）とされているため
  - 参考（前の版。二段階認証があるかどうかに関係なく最小8文字としていた。「8文字以上」が広まったのはこの版の影響が大きいが、今の版では、パスワードだけでログインする場合は15文字に変わった）：https://pages.nist.gov/800-63-3/sp800-63b.html
  - 参照（OWASP も同じ考え方。二段階認証があるなら8文字未満、ないなら15文字未満は弱い）：https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html
- 上限は `has_secure_password` が確認する72バイト（bcrypt が扱える長さ）。英数字なら72文字まで入るので、NIST の「最大の長さは、少なくとも64文字まで許すべき」（SHOULD）も満たす
  - 参照：https://api.rubyonrails.org/classes/ActiveModel/SecurePassword/ClassMethods.html#method-i-has_secure_password

### パフォーマンス（N+1）
- 目的は、追加のクエリを出しすぎずに、パフォーマンスを悪化させないこと。`includes` などのメソッドを使うこと自体が目的ではない
  - N+1：一覧のレコードN件を1回のクエリで取得したあと、それぞれの関連を取得するために、追加でN回のクエリが発行されてしまうこと（例：イベント一覧で、各イベントの作成者の名前を表示するたびに、管理者を1件ずつ取得する）
- 関連をまとめて読み込むときは、基本的に `includes` を使う。クエリの内容によって、`preload` か `eager_load` を自動で使い分けてくれるため
  - `includes` の自動の選択がクエリに合わない場合は、`preload` や `eager_load` を直接使う
- `includes` などをむやみに付けない。使う関連だけを、使う場面でまとめて読み込む
  - 理由：まとめて読み込んでも、Viewでその関連を使わなければ、取得したデータは無駄になり、かえってパフォーマンスを悪くするため
  - 例：イベント一覧で作成者の名前を表示するなら `includes(:administrator)` を付ける。表示しないなら付けない
- 一覧を作ったときは、開発環境のログで、1回の画面表示で発行されるクエリの数を確認する
  - 理由：strict loading がエラーにするのは「関連の遅延読み込み」で、`includes` による読み込みすぎ（読み込んだのに使っていない）は対象ではないため
    - 読み込みすぎの例：詳細画面の `Event.includes(:administrator, :event_entries)` を一覧に流用すると、一覧で使わない申込まで全件読み込む。strict loading は「読み込んでいない」ときだけエラーにし、「読み込んだのに使っていない」ことは見つけられない
- N+1 に機械的に気づけるよう、strict loading を `:n_plus_one_only` モードで全体に有効にしている

  | 環境 | 設定 | N+1 になる遅延読み込みが起きたとき |
  | --- | --- | --- |
  | 開発・テスト | `strict_loading_by_default = true`、`strict_loading_mode = :n_plus_one_only` | エラーになる（実装中やテストで気づいて直す） |
  | 本番 | 上に加えて `action_on_strict_loading_violation = :log` | エラーにせず、ログに出す（利用者の画面を止めない） |

  - `:n_plus_one_only` にする理由：全部の遅延読み込みを禁止すると（初期値の `:all`）、詳細画面で1件の作成者を表示するだけでもエラーになり、N+1 にならない場面でも `includes` が必要になるため。N+1 になるときだけ報告させる
  - 本番をログだけにする理由：見落としたN+1で利用者の画面がエラーになるのを防ぎつつ、ログから見つけて直せるようにするため
  - 参照（strict loading とは何か、全体で有効にする設定、ログに出す設定）：https://guides.rubyonrails.org/active_record_querying.html#strict-loading
  - 参照（`strict_loading_by_default` の説明と初期値 `false`）：https://guides.rubyonrails.org/v8.0/configuring.html#config-active-record-strict-loading-by-default
  - 参照（`strict_loading_mode` の説明と初期値 `:all`）：https://guides.rubyonrails.org/v8.0/configuring.html#config-active-record-strict-loading-mode
  - 参照（`action_on_strict_loading_violation` の説明と初期値 `:raise`）：https://guides.rubyonrails.org/v8.0/configuring.html#config-active-record-action-on-strict-loading-violation
- 参照（N+1 と、`includes` / `preload` / `eager_load` の使い分け）：https://guides.rubyonrails.org/active_record_querying.html#eager-loading-associations
- 参照（`includes` が推奨されること）：https://guides.rubyonrails.org/active_record_querying.html#includes

### タイムゾーン
- アプリのタイムゾーンを日本時間にする（`config/application.rb` に `config.time_zone = "Tokyo"`。設定済み）。`config.active_record.default_timezone`（DBに保存する日時と、DBから取り出す日時を、UTCとローカルのタイムゾーンのどちらで扱うかを決める設定）は、初期値の `:utc` から変えない
  - ここでの「ローカルのタイムゾーン」は、Railsが動いているサーバー（開発環境では Docker の `app` コンテナ。Dockerfile で `TZ=UTC`）のタイムゾーンで、`config.time_zone` の日本時間とは別のもの

  | | 時刻 | 決める設定 | 例：管理者が開催開始日時に「2026-11-22 18:00」と入力した場合 |
  | --- | --- | --- | --- |
  | 入力の解釈 | 日本時間 | `Time.zone`（＝ `config.time_zone`） | 日本時間の18:00として扱う（公式ドキュメントで直接の記述は見つかっていないが、動作で確認済み） |
  | DBへの保存 | UTC | `config.active_record.default_timezone` | UTCの09:00として保存する |
  | 画面の表示 | 日本時間 | `Time.zone`（＝ `config.time_zone`） | 18:00と表示する |

  - `Time.zone` は、リクエストの中で `Time.zone=` などで設定されていなければ、`config.time_zone` のタイムゾーンになる

  - 理由：会員も管理者も日本にいて、イベントも日本時間で開催されるため。アプリのタイムゾーンをUTCのままにすると、入力された「18:00」がUTCとして解釈され、日本時間では翌日の3:00として保存されてしまう
  - 利用者ごとにタイムゾーンを切り替える方法（アプリはUTCのまま、リクエストごとに利用者のタイムゾーンに切り替える）は採用しない。利用者が複数のタイムゾーンにいるサービス向けの方法で、日本だけのサービスでは、切り替えの仕組みを作るコストに見合わないため。海外の利用者を想定するようになったら移行する（DBはどちらもUTCなので、保存済みのデータを変換する必要はない）
- 現在時刻や日時の文字列は、アプリのタイムゾーンを使うメソッドで扱う

  | 使わない | 使う | 理由 |
  | --- | --- | --- |
  | `Time.now` | `Time.current` | `Time.now` は、Railsが動いているサーバー（開発環境では Docker の `app` コンテナ。Dockerfile で `TZ=UTC`）の時刻を使い、アプリのタイムゾーン（`config.time_zone`）を使わないため |
  | `Date.today` | `Date.current` | `Date.today` はシステム（Railsが動いているサーバー）のタイムゾーンを使い、`Date.current` はアプリのタイムゾーン（`config.time_zone`）を考慮するため。アプリのタイムゾーン（日本時間）はサーバーのタイムゾーン（UTC）より進んでいるので、日本時間の0:00〜9:00は `Date.today` が前日の日付になる（Railsガイドでも「`Date.today` が `Date.yesterday` と等しくなる可能性がある」とされている） |
  | `Time.parse(...)` | `Time.zone.parse(...)` | アプリのタイムゾーンで解釈するため |

- 参照（`config.time_zone` の説明）：https://guides.rubyonrails.org/v8.0/configuring.html#config-time-zone
- 参照（`config.active_record.default_timezone` は、DBから日時を取り出すときに `Time.utc` と `Time.local` のどちらを使うかを決める設定で、初期値は `:utc`）：https://guides.rubyonrails.org/v8.0/configuring.html#config-active-record-default-timezone
- 参照（タイムスタンプは標準でUTCで、`config.active_record.default_timezone = :local` にするとローカルのタイムゾーンになること）：https://api.rubyonrails.org/classes/ActiveRecord/Timestamp.html#module-activerecord-timestamp-active-record-timestamp
- 参照（`datetime` と `time` のカラムは、DBにUTCで保存され、取り出すときに `Time.zone` に変換されること）：https://api.rubyonrails.org/classes/ActiveRecord/Timestamp.html#module-activerecord-timestamp-time-zone-aware-attributes
- 参照（`Time.zone` は、リクエストの中で設定されていなければ `config.time_zone` のタイムゾーンを返すこと）：https://api.rubyonrails.org/classes/Time.html#method-c-zone
- 参照（`Time.current` は、`config.time_zone` が設定されていれば `Time.zone.now` を返すこと）：https://api.rubyonrails.org/classes/Time.html#method-c-current
- 参照（`Time.zone.now` は、`Time.zone` のタイムゾーンでの現在時刻を `ActiveSupport::TimeWithZone` で返すこと）：https://api.rubyonrails.org/classes/ActiveSupport/TimeZone.html#method-i-now
- 参照（`Time.parse` はRubyの標準ライブラリのメソッドで、文字列にタイムゾーンやオフセットがない場合は `zone` 引数で指定すること）：https://docs.ruby-lang.org/en/master/Time.html#method-c-parse
- 参照（`Time.zone.parse` は、文字列を解析して、`Time.zone` のタイムゾーンの時刻を作ること）：https://api.rubyonrails.org/classes/ActiveSupport/TimeZone.html#method-i-parse
- 参照（`Date.current` は、`config.time_zone` が設定されていれば `Time.zone.today` を返すこと）：https://api.rubyonrails.org/classes/Date.html#method-c-current
- 参照（`Date.today` はデフォルトでシステムのタイムゾーンを使うこと、日付を比べるときは `Date.today` ではなく `Date.current` を使うこと、`Date.today` が `Date.yesterday` と等しくなる可能性があること）：https://guides.rubyonrails.org/v8.0/active_support_core_extensions.html#date-current
- 参照（`Time.now` ではなく `Time.current`、`Time.parse` ではなく `Time.zone.parse` を使うこと、利用者ごとにタイムゾーンを切り替える方法。公式ではないが、Railsの分野で広く参照されている thoughtbot の記事「It's About Time (Zones)」）：https://thoughtbot.com/blog/its-about-time-zones

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
