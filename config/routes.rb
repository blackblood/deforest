Deforest::Engine.routes.draw do
  resources :files, param: :file_name do
    get 'dashboard', on: :collection
  end
end
