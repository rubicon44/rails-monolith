module User
  class EventEntriesController < BaseController
    def index
      # 自分の申込だけを探す（他の会員の申込は見せない）
      # 各申込のイベントのタイトルと開催期間を表示するので、includes でイベントをまとめて読み込む（申込ごとにイベントを読む N+1 を防ぐ）
      entries = EventEntry.where(member_id: current_member.id).includes(:event).order(created_at: :desc)
      render locals: { entries: entries }
    end

    def create
      event = Event.find(params[:event_id])
      # 会員は、フォームから受け取らず、ログイン中の会員にする（他の会員として申し込めないようにする）
      entry = EventEntry.new(event_id: event.id, member_id: current_member.id)

      if entry.save
        # 申し込んだ結果（承認待ち）を確かめられるよう、申込一覧に移る
        redirect_to event_entries_path, notice: "申し込みました"
      else
        redirect_to events_path, alert: entry.errors.full_messages.to_sentence
      end
    rescue ActiveRecord::RecordNotUnique
      # 同時に2回送られて、バリデーションをすり抜けた2件目は、DB の一意インデックスが拒否する
      redirect_to events_path, alert: "このイベントにはすでに申し込んでいます"
    end
  end
end
