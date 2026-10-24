module Admin
  class EventsController < BaseController
    def index
      render locals: { events: Event.order(held_start_at: :desc) }
    end

    def new
      render locals: { event: Event.new }
    end

    def create
      event = Event.new(event_params.merge(administrator: current_administrator))

      if event.save
        redirect_to admin_events_path, notice: "イベントを作成しました"
      else
        render :new, locals: { event: event }, status: :unprocessable_entity
      end
    end

    private

    # 進行状態（status）と作成者（administrator）は受け取らない（改ざんされたリクエストで、いきなり「開始」にしたり、別の管理者を作成者にしたりできないようにする）
    def event_params
      params.expect(event: [
        :title, :description, :male_capacity, :female_capacity,
        :entry_start_at, :entry_end_at, :held_start_at, :held_end_at
      ])
    end
  end
end
