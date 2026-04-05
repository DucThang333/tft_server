defmodule TftServer.Board do
  @moduledoc false

  alias TftServer.Board.BoardBootstrap
  alias TftServer.Repo

  def get_bootstrap do
    Repo.get!(BoardBootstrap, "default")
  end
end
