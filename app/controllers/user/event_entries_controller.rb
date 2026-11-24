module User
  class EventEntriesController < BaseController
    def create
      event = Event.find(params[:event_id])
      # 会員は、フォームから受け取らず、ログイン中の会員にする（他の会員として申し込めないようにする）
      entry = EventEntry.new(event_id: event.id, member_id: current_member.id)

      if entry.save
        # 申込一覧（GET /entries）を作ったら、申込一覧に移る
        redirect_to events_path, notice: "申し込みました"
      else
        redirect_to events_path, alert: entry.errors.full_messages.to_sentence
      end
    rescue ActiveRecord::RecordNotUnique
      # 同時に2回送られて、バリデーションをすり抜けた2件目は、DB の一意インデックスが拒否する
      redirect_to events_path, alert: "このイベントにはすでに申し込んでいます"
    end
  end
end
