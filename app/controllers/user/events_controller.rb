module User
  class EventsController < BaseController
    def index
      render locals: {
        events: Event.accepting_entries.order(:held_start_at),
        # 申込済みかどうかを、イベントごとに1件ずつ調べず、最初にまとめて取る（N+1 を防ぐ）
        applied_event_ids: EventEntry.where(member: current_member).pluck(:event_id)
      }
    end
  end
end
