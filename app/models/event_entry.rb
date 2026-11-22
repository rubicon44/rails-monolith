# 申込（イベント集約の一部）
class EventEntry < ApplicationRecord
  belongs_to :event
  belongs_to :member
end
