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

    test "nested with list" do
      data = %{r: [%{a: 1}, %{a: 2}, %{a: 3}, %{a: 4}]}

      assert {:ok, 1} = JsonpathToAccess.lookup(data, "$.r[0].a")
      assert {:ok, 2} = JsonpathToAccess.lookup(data, "$.r[1].a")
      assert {:ok, 3} = JsonpathToAccess.lookup(data, "$.r[2].a")
      assert {:ok, 4} = JsonpathToAccess.lookup(data, "$.r[3].a")
      assert {:ok, nil} = JsonpathToAccess.lookup(data, "$.r[4].a")
      assert {:ok, 3} = JsonpathToAccess.lookup(data, "$.r[-2].a")
      assert {:ok, [1, 2]} = JsonpathToAccess.lookup(data, "$.r[:2].a")
      assert {:ok, [1, 2]} = JsonpathToAccess.lookup(data, "$.r[0:2].a")
      assert {:ok, [3, 4]} = JsonpathToAccess.lookup(data, "$.r[-2:].a")

      assert {:ok, [1, 2, 3, 4]} = JsonpathToAccess.lookup(data, "$.r[*].a")
    end
  end
end
