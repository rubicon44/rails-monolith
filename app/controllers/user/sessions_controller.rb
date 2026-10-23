module User
  class SessionsController < BaseController
    # ログイン画面は、ログインしていない人が使う画面なので、BaseController のログインの確認（require_member_login）を外す
    # 外したので、ログイン中かどうかは new の中で確認する
    skip_before_action :require_member_login, only: %i[new create]

    def new
      # ログイン中の会員にはログイン画面を見せず、トップに移す。ログインしていない人にだけ、else 側で画面を表示する
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
        # 入力し直す手間を減らすため、メールアドレスだけを画面に戻す
        # パスワードは戻さない（戻すと、送り返す HTML にパスワードがそのまま入り、ページのソースやキャッシュに残るため）
        render :new, locals: { email_address: params[:email_address] }, status: :unprocessable_entity
      end
    end

    def destroy
      reset_session
      redirect_to login_path, status: :see_other
    end
  end
end
