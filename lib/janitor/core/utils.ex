defmodule Janitor.Core.Utils do
  @moduledoc false

  @spec new_id :: binary
  @spec string_id_to_binary(String.t()) :: binary
  @spec binary_id_to_string(binary) :: String.t()

  def new_id, do: UUID.uuid4()

  def string_id_to_binary(id), do: UUID.string_to_binary!(id)

  def binary_id_to_string(binary_id), do: UUID.binary_to_string!(binary_id)

  def random_string(length) do
    length |> :crypto.strong_rand_bytes() |> Base.url_encode64() |> binary_part(0, length)
  end
end
