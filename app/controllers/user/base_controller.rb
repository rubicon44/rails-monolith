# ユーザー画面の共通の親。ユーザー画面のコントローラーはすべてこれを継承する
module User
  class BaseController < ApplicationController
    before_action :require_member_login

    helper_method :current_member

    private

    def current_member
      # インスタンス変数でメモ化
      @current_member ||= Member.find_by(id: session[:member_id]) if session[:member_id]
    end

    def require_member_login
      redirect_to login_path unless current_member
    end

    # 会員登録とログインの両方で使う、ログインの手続き
    # 前のセッションを引き継がない（セッション固定攻撃を防ぐ）よう、reset_session してから会員 ID を入れる
    def log_in(member)
      reset_session
      session[:member_id] = member.id
    end
  end
end
