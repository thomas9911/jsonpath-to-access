defmodule JsonpathToAccess do
  @moduledoc """
  Documentation for `JsonpathToAccess`.
  """

  alias JsonpathToAccess.SafeComparisions

  def lookup(data, jsonpath) do
    opts = determine_opts(data)

    case convert(jsonpath, opts) do
      {:ok, access} ->
        resolved_access = resolve_absolute_paths(access, data)
        {:ok, get_in(data, resolved_access)}

      e ->
        e
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

  def resolve_absolute_paths(access, data) do
    Enum.map(access, &resolve_path(&1, data))
  end

  defp resolve_path({:absolute, {operator, converted_path, converted_absolute_path}}, data) do
    Access.filter(fn current_data ->
      with {:ok, resolved_data} <- fetch_in(data, converted_absolute_path),
           {:ok, data} <- fetch_in(current_data, converted_path) do
        compare(operator, data, resolved_data)
      else
        _ -> false
      end
    end)
  end

  defp resolve_path(path, _), do: path

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

  def map_to_access(
        {:query, {operator, {:relative_path, path}, {:absolute_path, absolute_path}}},
        opts
      ) do
    converted_path = to_access(path, opts)
    converted_absolute_path = to_access(absolute_path, opts)

    {:absolute, {operator, converted_path, converted_absolute_path}}
  end

  def map_to_access(
        {:query, {operator, {:relative_path, path_left}, {:relative_path, path_right}}},
        opts
      ) do
    converted_path_left = to_access(path_left, opts)
    converted_path_right = to_access(path_right, opts)

    Access.filter(fn current_data ->
      with {:ok, left_side} <- fetch_in(current_data, converted_path_left),
           {:ok, right_side} <- fetch_in(current_data, converted_path_right) do
        compare(operator, left_side, right_side)
      else
        _ -> false
      end
    end)
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
