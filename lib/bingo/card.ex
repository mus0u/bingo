defmodule Bingo.Card do
  import UUID, only: [uuid4: 0]
  defstruct [:id, :b, :i, :n, :g, :o]

  def new(:traditional, _opts) do
    %__MODULE__{
      id: uuid4(),
      b: generate_numeric_column(1..15),
      i: generate_numeric_column(16..30),
      n: generate_numeric_column(31..45, true),
      g: generate_numeric_column(46..60),
      o: generate_numeric_column(61..75)
    }
  end

  def new(:number_range, min: min, max: max) when is_integer(min) and is_integer(max) do
    range_list = Enum.to_list(min..max)
    chunk_size = div(length(range_list), 5)

    [b_range, i_range, n_range, g_range, o_range | leftovers] =
      Enum.chunk_every(range_list, chunk_size)

    %__MODULE__{
      id: uuid4(),
      b: generate_numeric_column(b_range),
      i: generate_numeric_column(i_range),
      n: generate_numeric_column(n_range, true),
      g: generate_numeric_column(g_range),
      o: generate_numeric_column(o_range ++ List.flatten(leftovers))
    }
  end

  def new(:custom_text, custom_text_entries: entries) when is_list(entries) do
    picks =
      entries
      |> Enum.shuffle()
      |> Enum.take(24)

    %__MODULE__{
      id: uuid4(),
      b: Enum.slice(picks, 0..4),
      i: Enum.slice(picks, 5..9),
      n: Enum.slice(picks, 10..11) ++ ["*"] ++ Enum.slice(picks, 12..13),
      g: Enum.slice(picks, 14..18),
      o: Enum.slice(picks, 19..23)
    }
  end

  defp generate_numeric_column(range, include_free_space? \\ false) do
    {_, result} =
      Enum.reduce(1..5, {range, []}, fn i, {range, result} ->
        if i == 3 and include_free_space? do
          {range, ["*" | result]}
        else
          [pick | remaining_range] = Enum.shuffle(range)
          {remaining_range, [pick | result]}
        end
      end)

    result
  end
end
