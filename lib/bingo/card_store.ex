defmodule Bingo.CardStore do
  alias Bingo.Card

  @table_name :card_store

  def init do
    :ets.new(@table_name, [:set, :public, :named_table, read_concurrency: true])
  end

  def bulk_create(params) do
    {count, params} = Keyword.pop_first(params, :count)
    {cell_type, params} = Keyword.pop_first(params, :cell_type)

    cards = for _ <- 1..count, do: Card.new(cell_type, params)
    insert_tuples = Enum.map(cards, &{&1.id, &1})
    :ets.insert(@table_name, insert_tuples)
    Enum.map(cards, & &1.id)
  end

  def fetch(id) do
    case :ets.lookup(@table_name, id) do
      [{^id, card}] -> {:ok, card}
      [] -> {:error, :not_found}
    end
  end
end
