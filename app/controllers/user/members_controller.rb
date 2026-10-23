module User
  class MembersController < BaseController
    # 会員登録の画面は、ログインしていない人が使う画面なので、BaseController のログインの確認（require_member_login）を外す
    # 外したので、ログイン中かどうかは new の中で確認する
    skip_before_action :require_member_login, only: %i[new create]

    def new
      # ログイン中の会員には会員登録の画面を見せず、トップに移す。ログインしていない人にだけ、else 側で画面を表示する
      if current_member
        redirect_to root_path
      else
        render locals: { member: Member.new }
      end
    end

    def create
      member = Member.new(member_params)

      if member.save
        log_in(member)
        redirect_to root_path, notice: "会員登録しました"
      else
        # 入力し直す手間を減らすため、入力した値を持った member をそのまま画面に戻す
        # member にはパスワードも入っているが、password_field は初期状態で値を出力しないため、パスワードは画面に戻らない
        # （View の password_field に value: を付けると、送り返す HTML にパスワードが入るので付けない）
        render :new, locals: { member: member }, status: :unprocessable_entity
      end
    end

    private

    def member_params
      params.expect(member: [ :name, :email_address, :password, :password_confirmation, :gender ])
    end
  end
end
