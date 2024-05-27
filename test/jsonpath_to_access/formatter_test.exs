defmodule JsonpathToAccess.FormatterTest do
  alias JsonpathToAccess.Formatter
  alias JsonpathToAccess.Parser

  use ExUnit.Case, async: true

  defp roundtrip(json_path) do
    json_path
    |> Parser.parse()
    |> elem(1)
    |> Formatter.format()
  end

  test "" do
    assert "$['address']['streetAddress'][3:123:3][*][0][1,2,3]" ==
             roundtrip("$.address.streetAddress[3:123:3][*][0][1,2,3]")
  end
end
