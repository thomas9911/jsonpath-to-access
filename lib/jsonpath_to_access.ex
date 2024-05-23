defmodule JsonpathToAccess do
  @moduledoc """
  Documentation for `JsonpathToAccess`.
  """

  def lookup(data, jsonpath) do
    opts = determine_opts(data)
    case convert(jsonpath, opts) do
      {:ok, access} ->  {:ok, get_in(data, access)}
      e -> e
    end
  end

  defp determine_opts(data) when is_map(data) and map_size(data) > 0 do
    {first_key, _} = Enum.at(data, 0)

    if is_atom(first_key) do
      [to_atoms: true]
    else
      []
    end
  end

  defp determine_opts(data) when is_list(data) do
    [to_atoms: true]
  end

  defp determine_opts(_), do: []

  def convert(jsonpath, opts \\ []) do
    case JsonpathToAccess.Parser.parse(jsonpath) do
      {:ok, instructions} -> {:ok, to_access(instructions, opts)}
      e -> e
    end
  end

  defp to_access(instructions, opts) do
    to_atoms = Access.get(opts, :to_atoms, false)

    Enum.map(instructions, &map_to_access(&1, to_atoms))
  end

  def map_to_access({:key, key}, true), do: String.to_existing_atom(key)
  def map_to_access({:key, key}, false), do: Access.key(key)
end
