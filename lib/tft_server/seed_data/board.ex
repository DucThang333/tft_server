defmodule TftServer.SeedData.Board do
  @moduledoc false

  def bootstrap_row do
    %{
      id: "default",
      synergies: [
        %{"id" => "syn-1", "name" => "Arcanist", "count" => 4},
        %{"id" => "syn-2", "name" => "Warden", "count" => 2},
        %{"id" => "syn-3", "name" => "Invoker", "count" => 2}
      ],
      board_champions: [
        %{"id" => "bc-1", "name" => "Ryze"},
        %{"id" => "bc-2", "name" => "Lux"},
        %{"id" => "bc-3", "name" => "Swain"}
      ],
      tray_champions: [
        %{"id" => "t1", "name" => "A"},
        %{"id" => "t2", "name" => "B"},
        %{"id" => "t3", "name" => "C"},
        %{"id" => "t4", "name" => "D"},
        %{"id" => "t5", "name" => "E"}
      ],
      board_items: [
        %{"id" => "item-1", "name" => "Item One"},
        %{"id" => "item-2", "name" => "Item Two"},
        %{"id" => "item-3", "name" => "Item Three"}
      ]
    }
  end
end
