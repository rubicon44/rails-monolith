Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"

  namespace :admin do
    root "dashboards#show"
    get    "login",  to: "sessions#new"
    post   "login",  to: "sessions#create"
    delete "logout", to: "sessions#destroy"

    resources :events, only: %i[index show new create]
  end

  # ユーザー画面（URL に接頭辞は付けず、コントローラーは User:: に置く）
  scope module: :user do
    root "dashboards#show"
    get    "login",  to: "sessions#new"
    post   "login",  to: "sessions#create"
    delete "logout", to: "sessions#destroy"

    resources :members, only: %i[new create]
    resources :events, only: %i[index] do
      # 会員の申込は、1つのイベントに1回だけなので、単数形リソースにする（URL に申込の ID を持たない）
      # URL は /events/:event_id/entry と短くし、コントローラー名はモデル（EventEntry）にそろえる（同じ名前で検索できるようにするため）
      resource :entry, only: %i[create], controller: "event_entries"
    end
    # 自分の申込の一覧（GET /event_entries）。リソース名・URL・コントローラー・ヘルパー名を、モデル（EventEntry）にそろえる
    resources :event_entries, only: %i[index]
  end
end
