Rails.application.routes.draw do
  resources :terms, only: :show
  resources :people, only: :show
  resources :governments, only: :show

  get '/', to: 'pages#home'
end
