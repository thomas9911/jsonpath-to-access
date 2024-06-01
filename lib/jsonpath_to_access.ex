defmodule JsonpathToAccess do
  @moduledoc """
  This module provides a function to convert a JSONPath expression into an access path.
  This library does not support all of jsonpath:

  - the `..` operator is not supported because it can't be expressed using Access functions (that I know of)
  - all the functions like length for the same reason as above

  There are two main methods:

  - `convert/2` and `get_in/2`

  Convert the JSONPath expression into an access path. This function is used by the `get_in/2` function.
  You have to specify upfront if the data contains atom keys or not.
  You can cache or put the convert in a module attribute.

  ```elixir
  iex> path = JsonpathToAccess.convert!("$.store.book[0].author", to_atoms: true)
  iex> JsonpathToAccess.get_in(%{store: %{book: [%{author: "Gandalf"}]}}, path)
  "Gandalf"
  ```

  ```elixir
  defmodule MyModule do
    @json_path JsonpathToAccess.convert!("$.store.book[0].author")

    def my_lookup(data) do
      # or you can use the normal get_in if you don't use absolute path filter.
      JsonpathToAccess.get_in(data, @json_path)
    end
  end
  ```

  - `lookup/2`

  Just lookup the value in a map using the JSONPath expression.

  ```elixir
  iex> JsonpathToAccess.lookup(%{store: %{book: [%{author: "Gandalf"}]}}, "$.store.book[0].author")
  {:ok, "Gandalf"}
  ```

  """
  import Kernel, except: [get_in: 2]

  alias JsonpathToAccess.SafeComparisions

  @type access_path :: list
  @type options :: keyword
  @type operator :: :equals | :not_equals | :lesser | :greater | :lesser_equals | :greater_equals

  @doc """
  Looks up data using a JSONPath.

  ```elixir
  iex> JsonpathToAccess.lookup(%{"a" => %{"b" => 1}}, "$.a.b")
  {:ok, 1}
  iex> JsonpathToAccess.lookup(%{a: %{b: 1}}, "$.a.b")
  {:ok, 1}
  iex> JsonpathToAccess.lookup([a: [[b: 1], [b: 2], [b: 3]]], "$.a[?(@.b >= 2)].b")
  {:ok, [2, 3]}
  ```
  """
  @spec lookup(Access.t(), binary) :: {:ok, term} | {:error, binary}
  def lookup(data, jsonpath) do
    opts = determine_opts(data)

    case convert(jsonpath, opts) do
      {:ok, access} ->
        {:ok, get_in(data, access)}

      e ->
        e
    end
  end

  @doc """
  Similar to `Kernel.get_in/2`, but it resolves the absolute values.
  """
  @spec get_in(Access.t(), access_path) :: term | nil
  def get_in(data, access) do
    resolved_access = resolve_absolute_paths(access, data)
    Kernel.get_in(data, resolved_access)
  end

  defp determine_opts(data) when is_struct(data) or is_list(data) do
    [to_atoms: true]
  end

  defp determine_opts(data) when is_map(data) and map_size(data) > 0 do
    {first_key, _} = Enum.at(data, 0)

    if is_atom(first_key) do
      [to_atoms: true]
    else
      []
    end
  end

  defp determine_opts(_), do: []

  defp resolve_absolute_paths(access, data) do
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

  @doc """
  Converts a JSONPath into an Access path.
  This can be used later with the `JsonpathToAccess.get_in/2` function.

  ```elixir
  iex> {:ok, access_path} = JsonpathToAccess.convert("$.a.b")
  iex> JsonpathToAccess.get_in(%{"a" => %{"b" => "value"}}, access_path)
  "value"
  iex> {:ok, access_path} = JsonpathToAccess.convert("$.a.b", to_atoms: true)
  iex> JsonpathToAccess.get_in(%{a: %{b: "value"}}, access_path)
  "value"
  ```
  """
  @spec convert(binary, options) :: {:ok, access_path} | {:error, binary}
  def convert(jsonpath, opts \\ []) do
    case JsonpathToAccess.Parser.parse(jsonpath) do
      {:ok, instructions} -> {:ok, to_access(instructions, opts)}
      e -> e
    end
  end

  @doc """
  Converts a JSONPath into an Access path.
  This can be used later with the `JsonpathToAccess.get_in/2` function.

  ```elixir
  iex> access_path = JsonpathToAccess.convert!("$.a.b")
  iex> JsonpathToAccess.get_in(%{"a" => %{"b" => "value"}}, access_path)
  "value"
  iex> access_path = JsonpathToAccess.convert!("$.a.b", to_atoms: true)
  iex> JsonpathToAccess.get_in(%{a: %{b: "value"}}, access_path)
  "value"
  ```
  """
  @spec convert!(binary, options) :: access_path
  def convert!(jsonpath, opts \\ []) do
    case JsonpathToAccess.Parser.parse(jsonpath) do
      {:ok, instructions} -> to_access(instructions, opts)
      _e -> raise "Invalid JSONPath: #{jsonpath}"
    end
  end

  @spec to_access(list, options | map) :: access_path
  defp to_access(instructions, opts) do
    Enum.map(instructions, &map_to_access(&1, Map.new(opts)))
  end

  @spec map_to_access({atom, term}, map) :: term
  defp map_to_access({:key, key}, %{to_atoms: true}), do: String.to_existing_atom(key)
  defp map_to_access({:key, key}, %{}), do: Access.key(key)
  defp map_to_access({:select_index, index}, _), do: Access.at(index)
  defp map_to_access({:select_range, range}, _), do: Access.slice(range)
  defp map_to_access({:select_all, _}, _), do: Access.all()

  defp map_to_access({:query, {:contains, {:relative_path, path}}}, opts) when is_list(path) do
    converted_path = to_access(path, opts)
    Access.filter(&match?({:ok, _}, fetch_in(&1, converted_path)))
  end

  defp map_to_access({:query, {:not_contains, {:relative_path, path}}}, opts)
       when is_list(path) do
    converted_path = to_access(path, opts)
    Access.filter(&match?(:error, fetch_in(&1, converted_path)))
  end

  defp map_to_access(
         {:query, {operator, {:relative_path, path}, {:absolute_path, absolute_path}}},
         opts
       ) do
    converted_path = to_access(path, opts)
    converted_absolute_path = to_access(absolute_path, opts)

    {:absolute, {operator, converted_path, converted_absolute_path}}
  end

  defp map_to_access(
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

  defp map_to_access({:query, {operator, {:relative_path, path}, literal}}, opts) do
    converted_path = to_access(path, opts)

    Access.filter(fn current_data ->
      case fetch_in(current_data, converted_path) do
        {:ok, data} -> compare(operator, data, literal)
        _ -> false
      end
    end)
  end

  @spec compare(operator, term, term) :: boolean
  defp compare(:equals, data, literal), do: SafeComparisions.==(data, literal)
  defp compare(:not_equals, data, literal), do: SafeComparisions.!=(data, literal)
  defp compare(:greater, data, literal), do: SafeComparisions.>(data, literal)
  defp compare(:greater_equals, data, literal), do: SafeComparisions.>=(data, literal)
  defp compare(:lesser, data, literal), do: SafeComparisions.<(data, literal)
  defp compare(:lesser_equals, data, literal), do: SafeComparisions.<=(data, literal)

  @doc """
  The missing `fetch_in` function from `Kernel`.

  Probably not exactly what you want, internally used for looking up if a value exists in a nested map.
  """
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
