defmodule BingoWeb.Router do
  use BingoWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {BingoWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", BingoWeb do
    pipe_through :browser

    get "/", RootController, :index

    resources "/cards", CardController, only: [:create, :show]
  end
end
