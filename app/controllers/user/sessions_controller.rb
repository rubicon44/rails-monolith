module User
  class SessionsController < BaseController
    # ログインしていない人が使う画面なので、ログインの確認を外す（ログイン中かどうかは new で確認する）
    skip_before_action :require_member_login, only: %i[new create]

    def new
      # ログイン中の会員にはログイン画面を見せず、トップに移す
      if current_member
        redirect_to root_path
      else
        render locals: { email_address: nil }
      end
    end

    def create
      member = Member.authenticate_by(email_address: params[:email_address], password: params[:password])

      if member
        log_in(member)
        redirect_to root_path
      else
        flash.now[:alert] = "メールアドレスまたはパスワードが違います"
        # 入力し直す手間を減らすため、メールアドレスだけを戻す（パスワードは、戻すと HTML に残るので戻さない）
        render :new, locals: { email_address: params[:email_address] }, status: :unprocessable_entity
      end
    end

    def destroy
      reset_session
      redirect_to login_path, status: :see_other
    end
  end
end
