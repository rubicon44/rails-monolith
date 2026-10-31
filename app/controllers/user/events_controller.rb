module User
  class EventsController < BaseController
    def index
      render locals: { events: Event.upcoming.order(:held_start_at) }
    end
  end
end
