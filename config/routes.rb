Deforest::Engine.routes.draw do
  get "/files", controller: "files", action: "index"
  get "/file", controller: "files", action: "show"
  get "/files/dashboard", controller: "files", action: "dashboard"
end
