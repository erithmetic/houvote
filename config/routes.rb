Rails.application.routes.draw do
  resources :terms
  resources :people
  resources :governments

  get '/', to: 'pages#home'
end
