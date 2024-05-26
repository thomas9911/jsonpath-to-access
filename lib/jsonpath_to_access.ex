defmodule JsonpathToAccess do
  @moduledoc """
  Documentation for `JsonpathToAccess`.
  """

  def lookup(data, jsonpath) do
    opts = determine_opts(data)

    case convert(jsonpath, opts) do
      {:ok, access} -> {:ok, get_in(data, access)}
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
    Enum.map(instructions, &map_to_access(&1, Map.new(opts)))
  end

  def map_to_access({:key, key}, %{to_atoms: true}), do: String.to_existing_atom(key)
  def map_to_access({:key, key}, %{}), do: Access.key(key)
  def map_to_access({:select_index, index}, _), do: Access.at(index)
  def map_to_access({:select_range, range}, _), do: Access.slice(range)
  def map_to_access({:select_all, _}, _), do: Access.all()

  def map_to_access({:query, {:relative_path, path}}, opts) do
    converted_path = to_access(path, opts)

    Access.filter(fn current_data ->
      match?({:ok, _}, fetch_in(current_data, converted_path))
    end)
  end

  def filtering({pointer, comparison, value}) do
    # accessing = to_access(pointer, [])

    fn _, data, next ->
      IO.inspect(data)
      res = Enum.at(data, 0)
      next.(res)
    end
  end

  @spec fetch_in(Access.t(), nonempty_list(term)) :: {:ok, term} | :error
  def fetch_in(data, keys)

  # probably this next line doesnt work as expected
  def fetch_in({:ok, data}, [h]) when is_function(h), do: h.(:get, data, & &1)
  def fetch_in({:ok, data}, [h | t]) when is_function(h), do: h.(:get, data, &fetch_in(&1, t))

  def fetch_in(:error, [_]), do: :error
  def fetch_in(:error, [_ | _]), do: :error

  def fetch_in({:ok, data}, [h]), do: Access.fetch(data, h)
  def fetch_in({:ok, data}, [h | t]), do: fetch_in(Access.fetch(data, h), t)
  def fetch_in(data, keys), do: fetch_in({:ok, data}, keys)
end
