defmodule TftServer.DataCase do
  @moduledoc false

  use ExUnit.CaseTemplate

  using do
    quote do
      alias TftServer.Repo

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import TftServer.DataCase
    end
  end

  setup tags do
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(TftServer.Repo, shared: not tags[:async])

    on_exit(fn ->
      Ecto.Adapters.SQL.Sandbox.stop_owner(pid)
    end)

    :ok
  end
end
