module Admin
  class SessionsController < BaseController
    # ログイン画面は、ログインしていない人が使う画面なので、BaseController のログインの確認（require_admin_login）を外す
    # 外したので、ログイン中かどうかは new の中で確認する
    skip_before_action :require_admin_login, only: %i[new create]

    def new
      # ログイン中の管理者にはログイン画面を見せず、管理画面トップに移す。ログインしていない人にだけ、else 側で画面を表示する
      if current_administrator
        redirect_to admin_root_path
      else
        render locals: { email_address: nil }
      end
    end

    def create
      # メールアドレス・パスワード認証
      administrator = Administrator.authenticate_by(email_address: params[:email_address], password: params[:password])

      if administrator
        reset_session
        session[:administrator_id] = administrator.id
        redirect_to admin_root_path
      else
        flash.now[:alert] = "メールアドレスまたはパスワードが違います"
        render :new, locals: { email_address: params[:email_address] }, status: :unprocessable_entity
      end
    end

    def destroy
      reset_session
      redirect_to admin_login_path, status: :see_other
    end
  end
end
