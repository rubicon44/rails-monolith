# イベント（イベント集約のルート）
class Event < ApplicationRecord
  belongs_to :administrator

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
  validates :male_capacity, :female_capacity, numericality: { only_integer: true, greater_than_or_equal_to: 1 }
  validates :entry_start_at, :entry_end_at, :held_start_at, :held_end_at, presence: true
  validate :periods_must_be_in_order
  validate :start_times_must_be_in_future, on: :create

  # 開催予定のイベント（開催開始日時が現在以降）。会員に見せるイベント
  scope :upcoming, -> { where(held_start_at: Time.current..) }

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
