module User
  class EventsController < BaseController
    def index
      render locals: { events: Event.accepting_entries.order(:held_start_at) }
    end
  end
end
