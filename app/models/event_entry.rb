# 申込（イベント集約の一部）
# 承認は、定員を守るため Event#approve_entry を通す（entry.approved! を直接呼ぶと、定員の確認をすり抜ける）
class EventEntry < ApplicationRecord
  belongs_to :event
  belongs_to :member

  enum :status, {
    pending: "pending",     # 承認待ち
    approved: "approved"    # 承認済み
  }, validate: true

  # 1人の会員は、1つのイベントに1回だけ申し込める
  # 同時に2回送られたときは、このバリデーションでは防げないので、DB の一意インデックス [event_id, member_id] が防ぐ
  validates :member_id, uniqueness: { scope: :event_id }
  validate :event_must_be_accepting_entries, on: :create

  private

  # 申込は、受付中のイベントにだけできる（受付中かどうかは、event.entry_status で決まる）
  # これは申し込むときのルールなので、作成時だけ確認する
  # 承認（approved! による更新）は、受付終了後にも行う。更新時にも確認すると、受付終了後は event.entry_status が :closed なので、このバリデーションがエラーを出し、承認の保存が失敗する
  def event_must_be_accepting_entries
    # event がないときは、belongs_to のエラーだけを出すため確認しない
    return if event.nil?

    errors.add(:base, "受付中のイベントではありません") unless event.entry_status == :accepting
  end
end
