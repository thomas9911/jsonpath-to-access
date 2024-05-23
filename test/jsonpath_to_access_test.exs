defmodule JsonpathToAccessTest do
  use ExUnit.Case
  doctest JsonpathToAccess


  describe "lookup" do
    test "keyword" do
      data = [r: 1, z: 4]
      assert {:ok, 1} = JsonpathToAccess.lookup(data, "$.r")
      assert {:ok, 4} = JsonpathToAccess.lookup(data, "$.z")
      assert {:ok, nil} = JsonpathToAccess.lookup(data, "$.p")
    end

    test "atom map" do
      data = %{r: 1, z: 4}
      assert {:ok, 1} = JsonpathToAccess.lookup(data, "$.r")
      assert {:ok, 4} = JsonpathToAccess.lookup(data, "$.z")
      assert {:ok, nil} = JsonpathToAccess.lookup(data, "$.p")
    end

    test "string map" do
      data = %{"r" => 1, "z" => 4}
      assert {:ok, 1} = JsonpathToAccess.lookup(data, "$.r")
      assert {:ok, 4} = JsonpathToAccess.lookup(data, "$.z")
      assert {:ok, nil} = JsonpathToAccess.lookup(data, "$.p")
    end
  end
end
