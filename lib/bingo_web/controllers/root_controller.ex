defmodule BingoWeb.RootController do
  use BingoWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
