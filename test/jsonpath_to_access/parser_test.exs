defmodule JsonpathToAccess.ParserTest do
  use ExUnit.Case

  test "books" do
    assert {:ok, [{:key, "books"}]} = JsonpathToAccess.Parser.parse("$.books")
  end

  test "a" do
    assert {:ok, [{:key, "a"}]} = JsonpathToAccess.Parser.parse("$.a")
  end
end
