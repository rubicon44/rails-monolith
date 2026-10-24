module User
  class MembersController < BaseController
    # ログインしていない人が使う画面なので、ログインの確認を外す（ログイン中かどうかは new で確認する）
    skip_before_action :require_member_login, only: %i[new create]

    def new
      # ログイン中の会員には会員登録の画面を見せず、トップに移す
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
        # member にはパスワードも入っているが、password_field は値を出力しないので画面には戻らない（View で value: を付けない）
        render :new, locals: { member: member }, status: :unprocessable_entity
      end
    end

    private

    def member_params
      params.expect(member: [ :name, :email_address, :password, :password_confirmation, :gender ])
    end
  end
end
