# 管理画面の共通の親。管理画面のコントローラーはすべてこれを継承する
module Admin
  class BaseController < ApplicationController
    before_action :require_admin_login

    helper_method :current_administrator

    private

    def current_administrator
      # インスタンス変数でメモ化
      @current_administrator ||= Administrator.find_by(id: session[:administrator_id]) if session[:administrator_id]
    end

    def require_admin_login
      redirect_to admin_login_path unless current_administrator
    end
  end
end
