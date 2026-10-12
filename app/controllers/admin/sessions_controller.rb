module Admin
  class SessionsController < BaseController
    skip_before_action :require_admin_login, only: %i[new create]

    def new
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
