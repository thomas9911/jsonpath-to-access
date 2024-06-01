defmodule JsonpathToAccess.Formatter do
  @moduledoc """
  This module is responsible for formatting the AST into a string that can be used to access the JSON data.
  """

  @type tree :: JsonpathToAccess.access_path()

  @spec format(tree, keyword) :: binary
  def format(tree, opts \\ []) do
    tree
    |> format_to_iolist(opts)
    |> IO.iodata_to_binary()
  end

  @spec format_to_iolist(tree, keyword) :: iolist
  def format_to_iolist(tree, opts \\ []) do
    format_absolute_path_to_iolist(tree, opts)
  end

  @spec format_absolute_path_to_iolist(tree, keyword) :: iolist
  defp format_absolute_path_to_iolist(tree, opts) do
    ["$", Enum.map(tree, &format_item_iolist(&1, opts))]
  end

  @spec format_relative_path_to_iolist(tree, keyword) :: iolist
  defp format_relative_path_to_iolist(tree, opts) do
    ["@", Enum.map(tree, &format_item_iolist(&1, opts))]
  end

  @spec format_item_iolist(tuple, keyword) :: iodata
  defp format_item_iolist({:key, key}, _), do: "['#{key}']"
  defp format_item_iolist({:select_index, key}, _), do: "[#{key}]"

  defp format_item_iolist({:select_range, %Range{first: first, last: last, step: 1}}, _) do
    "[#{first}:#{last + 1}]"
  end

  defp format_item_iolist({:select_range, %Range{first: first, last: last, step: step}}, _) do
    "[#{first}:#{last + 1}:#{step}]"
  end

  defp format_item_iolist({:select_multi_index, range}, _), do: ["[", Enum.join(range, ","), "]"]
  defp format_item_iolist({:select_all, _}, _), do: "[*]"

  defp format_item_iolist({:query, {operator, {:relative_path, path}, value}}, opts) do
    ops = format_operator(operator)
    formatted_key = format_relative_path_to_iolist(path, opts)
    formatted_value = format_value(value, opts)

    ["[?(", formatted_key, " ", ops, " ", formatted_value, ")]"]
  end

  @spec format_operator(JsonpathToAccess.operator()) :: binary
  defp format_operator(:equals), do: "=="
  defp format_operator(:not_equals), do: "!="
  defp format_operator(:lesser), do: "<"
  defp format_operator(:greater), do: ">"
  defp format_operator(:lesser_equals), do: "<="
  defp format_operator(:greater_equals), do: ">="

  @spec format_value(binary | number | {:relative_path, tree}, term) :: binary
  defp format_value(value, _) when is_binary(value), do: "'#{value}'"
  defp format_value(value, _) when is_number(value), do: "#{value}"

  defp format_value({:relative_path, path}, opts) do
    format_relative_path_to_iolist(path, opts)
  end

  defp format_value({:absolute_path, path}, opts) do
    format_absolute_path_to_iolist(path, opts)
  end
end
