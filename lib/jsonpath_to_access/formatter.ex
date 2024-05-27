defmodule JsonpathToAccess.Formatter do
  def format(tree, opts \\ []) do
    tree
    |> format_to_iolist(opts)
    |> IO.iodata_to_binary()
  end

  def format_to_iolist(tree, opts \\ []) do
    ["$", Enum.map(tree, &format_item_iolist(&1, opts))]
  end

  defp format_item_iolist({:key, key}, _), do: "['#{key}']"
  defp format_item_iolist({:select_index, key}, _), do: "[#{key}]"

  defp format_item_iolist({:select_range, %Range{first: first, last: last, step: 1}}, _) do
    "[#{first}:#{last + 1}]"
  end

  defp format_item_iolist({:select_range, %Range{first: first, last: last, step: step}}, _) do
    "[#{first}:#{last + 1}:#{step}]"
  end

  defp format_item_iolist({:select_multi_index, range}, _), do: "[#{Enum.join(range, ",")}]"
  defp format_item_iolist({:select_all, _}, _), do: "[*]"
end
