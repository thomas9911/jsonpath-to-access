defmodule JsonpathToAccess do
  @moduledoc """
  Documentation for `JsonpathToAccess`.
  """

  alias JsonpathToAccess.SafeComparisions

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

  def map_to_access({:query, {:contains, {:relative_path, path}}}, opts) do
    converted_path = to_access(path, opts)
    Access.filter(&match?({:ok, _}, fetch_in(&1, converted_path)))
  end

  def map_to_access({:query, {:not_contains, {:relative_path, path}}}, opts) do
    converted_path = to_access(path, opts)
    Access.filter(&match?(:error, fetch_in(&1, converted_path)))
  end

  def map_to_access({:query, {operator, {:relative_path, path}, literal}}, opts) do
    converted_path = to_access(path, opts)

    Access.filter(fn current_data ->
      case fetch_in(current_data, converted_path) do
        {:ok, data} -> compare(operator, data, literal)
        _ -> false
      end
    end)
  end

  defp compare(:equals, data, literal), do: SafeComparisions.==(data, literal)
  defp compare(:not_equals, data, literal), do: SafeComparisions.!=(data, literal)
  defp compare(:greater, data, literal), do: SafeComparisions.>(data, literal)
  defp compare(:greater_equals, data, literal), do: SafeComparisions.>=(data, literal)
  defp compare(:lesser, data, literal), do: SafeComparisions.<(data, literal)
  defp compare(:lesser_equals, data, literal), do: SafeComparisions.<=(data, literal)

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
