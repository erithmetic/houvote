Rails.application.routes.draw do
  resources :terms, only: :show
  resources :officials, only: :show
  resources :divisions, only: :show
  resources :governments, only: :show

  get '/', to: 'pages#home'
end
