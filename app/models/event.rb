# イベント（イベント集約のルート）
class Event < ApplicationRecord
  belongs_to :administrator
  has_many :event_entries, dependent: :restrict_with_error

  enum :status, {
    scheduled: "scheduled",                 # 開催前
    ready: "ready",                         # 準備完了
    started: "started",                     # 開始
    talk_time: "talk_time",                 # トークタイム
    result_announced: "result_announced",   # 結果発表
    finished: "finished"                    # 終了
  }, validate: true

  validates :title, presence: true, length: { maximum: 100 }
  validates :description, presence: true
  # 会場の住所は、都道府県名から書く（イベントは日本で開催するため）
  PREFECTURES = %w[
    北海道 青森県 岩手県 宮城県 秋田県 山形県 福島県
    茨城県 栃木県 群馬県 埼玉県 千葉県 東京都 神奈川県
    新潟県 富山県 石川県 福井県 山梨県 長野県 岐阜県 静岡県 愛知県
    三重県 滋賀県 京都府 大阪府 兵庫県 奈良県 和歌山県
    鳥取県 島根県 岡山県 広島県 山口県
    徳島県 香川県 愛媛県 高知県
    福岡県 佐賀県 長崎県 熊本県 大分県 宮崎県 鹿児島県 沖縄県
  ].freeze

  # 前後の空白（全角スペースも含む）を取り除いてから保存する
  normalizes :venue_address, with: -> address { address.gsub(/\A[[:space:]]+|[[:space:]]+\z/, "") }

  # format：文字列の先頭が、47都道府県のどれかで始まる（空のときは presence のエラーだけを出すため、allow_blank で確認しない）
  validates :venue_address, presence: true, length: { maximum: 200 },
    format: { with: /\A(#{PREFECTURES.join("|")})/, message: "は都道府県名から入力してください", allow_blank: true }
  validates :male_capacity, :female_capacity, numericality: { only_integer: true, greater_than_or_equal_to: 1 }
  validates :entry_start_at, :entry_end_at, :held_start_at, :held_end_at, presence: true
  validate :periods_must_be_in_order
  validate :start_times_must_be_in_future, on: :create

  # 受付中のイベント（申込開始日時 ≦ 現在 ＜ 申込終了日時）。会員に見せるのは、受付中のイベントだけ
  # 申込終了日時ちょうどは受付終了にする（entry_status と同じ境界）。範囲では「現在より後」を書けないので、where.not で「現在以前ではない」と書く
  scope :accepting_entries, -> {
    now = Time.current
    where(entry_start_at: ..now).where.not(entry_end_at: ..now)
  }

  # 受付状態。申込期間と現在の日時から決まるので、DB には保存しない
  def entry_status
    now = Time.current
    if now < entry_start_at
      :not_yet_open
    elsif now < entry_end_at
      :accepting
    else
      :closed
    end
  end

  private

  # 申込開始 < 申込終了 ≦ 開催開始 < 開催終了 になっているかを確認する
  # validates の comparison で1つずつ書くと、1つの前後関係が3行のバリデーションに分かれ、全体の順番が読み取りにくくなる。1つのメソッドにまとめて、前後関係の全体を1か所で読めるようにする（DBの CHECK 制約 events_periods_in_order と同じ単位）
  def periods_must_be_in_order
    # 日時のどれかが空のときは、presence のエラーだけを出すため確認しない
    return if [ entry_start_at, entry_end_at, held_start_at, held_end_at ].any?(&:nil?)

    errors.add(:entry_end_at, "は申込開始日時より後にしてください") unless entry_start_at < entry_end_at
    errors.add(:held_start_at, "は申込終了日時以降にしてください") unless entry_end_at <= held_start_at
    errors.add(:held_end_at, "は開催開始日時より後にしてください") unless held_start_at < held_end_at
  end

  def start_times_must_be_in_future
    now = Time.current
    errors.add(:entry_start_at, "は現在より後にしてください") if entry_start_at.present? && entry_start_at <= now
    errors.add(:held_start_at, "は現在より後にしてください") if held_start_at.present? && held_start_at <= now
  end
end
