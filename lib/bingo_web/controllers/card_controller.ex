defmodule BingoWeb.CardController do
  use BingoWeb, :controller

  alias Bingo.CardStore
  alias BingoWeb.ErrorView

  @min_card_count 1
  @max_card_count 500
  @min_number_range_min 1
  @max_number_range_min 10_000
  @min_number_range_max 1
  @max_number_range_max 10_000

  def create(conn, params) do
    with {:ok, valid_params} <- parse_create_params(params) do
      card_ids = CardStore.bulk_create(valid_params)
      card_urls = Enum.map(card_ids, &Routes.card_path(conn, :show, &1))
      render(conn, "create.html", card_urls: card_urls, count: valid_params[:count])
    else
      {:error, reason} ->
        message =
          case reason do
            :invalid_card_count -> "Invalid number of cards to generate."
            :invalid_number_range_min -> "Invalid minimum value for custom number range."
            :invalid_number_range_max -> "invalid maximum value for custom number range."
            :number_range_too_small -> "Custom number range too small."
            :invalid_custom_text_entries -> "invalid custom text entries."
          end

        conn
        |> put_flash(:error, message)
        |> redirect(to: Routes.root_path(conn, :index))
    end
  end

  def show(conn, %{"id" => id}) do
    case CardStore.fetch(id) do
      {:ok, card} ->
        render(conn, "show.html", card: card)

      {:error, :not_found} ->
        conn
        |> put_view(ErrorView)
        |> put_status(:not_found)
        |> render("404.html")
    end
  end

  defp parse_create_params(%{"card_count" => count} = params) when is_binary(count) do
    with {int_count, ""} <- Integer.parse(count),
         true <- int_count >= @min_card_count and int_count < @max_card_count do
      params
      |> Map.put("card_count", int_count)
      |> parse_create_params()
    else
      _ -> {:error, :invalid_card_count}
    end
  end

  defp parse_create_params(%{"cell_type" => "traditional", "card_count" => count})
       when is_integer(count) do
    {:ok, [cell_type: :traditional, count: count]}
  end

  defp parse_create_params(%{
         "cell_type" => "number_range",
         "card_count" => count,
         "number_range_min" => min,
         "number_range_max" => max
       })
       when is_integer(count) do
    with {:parse_min, {int_min, ""}} <- {:parse_min, Integer.parse(min)},
         {:min_in_range, true} <-
           {:min_in_range, int_min >= @min_number_range_min and int_min <= @max_number_range_min},
         {:parse_max, {int_max, ""}} <- {:parse_max, Integer.parse(max)},
         {:max_in_range, true} <-
           {:max_in_range, int_max >= @min_number_range_max and int_max <= @max_number_range_max},
         {:valid_range_size, true} <- {:valid_range_size, int_max - int_min > 23} do
      parsed_params = [
        cell_type: :number_range,
        count: count,
        min: int_min,
        max: int_max
      ]

      {:ok, parsed_params}
    else
      {:parse_min, :error} -> {:error, :invalid_number_range_min}
      {:min_in_range, false} -> {:error, :invalid_number_range_min}
      {:parse_max, :error} -> {:error, :invalid_number_range_max}
      {:max_in_range, false} -> {:error, :invalid_number_range_max}
      {:valid_range_size, false} -> {:error, :number_range_too_small}
    end
  end

  defp parse_create_params(%{
         "cell_type" => "custom_text",
         "card_count" => count,
         "custom_text_entries" => entries
       })
       when is_integer(count) do
    with parsed_entries <- String.split(entries, "\r\n"),
         true <- length(parsed_entries) > 23 do
      parsed_params = [
        cell_type: :custom_text,
        count: count,
        custom_text_entries: parsed_entries
      ]

      {:ok, parsed_params}
    else
      _ -> {:error, :invalid_custom_text_entries}
    end
  end
end
