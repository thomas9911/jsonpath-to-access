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
      assert {:ok, 1} = JsonpathToAccess.lookup(data, "$['r']")
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
      assert {:ok, 2} = JsonpathToAccess.lookup(data, "$['r'][1]['a']")
      assert {:ok, 3} = JsonpathToAccess.lookup(data, "$.r[2].a")
      assert {:ok, 4} = JsonpathToAccess.lookup(data, "$.r[3].a")
      assert {:ok, nil} = JsonpathToAccess.lookup(data, "$.r[4].a")
      assert {:ok, 3} = JsonpathToAccess.lookup(data, "$.r[-2].a")
      assert {:ok, [1, 2]} = JsonpathToAccess.lookup(data, "$.r[:2].a")
      assert {:ok, [1, 2]} = JsonpathToAccess.lookup(data, "$.r[0:2].a")
      assert {:ok, [3, 4]} = JsonpathToAccess.lookup(data, "$.r[-2:].a")

      assert {:ok, [1, 2, 3, 4]} = JsonpathToAccess.lookup(data, "$.r[*].a")
    end

    test "query simple" do
      data = %{
        r: [%{a: 1}, %{a: 2, b: nil}, %{a: 3}, %{a: 4, b: 0}]
      }

      assert {:ok, [2, 4]} = JsonpathToAccess.lookup(data, "$.r[?(@.b)].a")
      assert {:ok, [1, 3]} = JsonpathToAccess.lookup(data, "$.r[?(!@.b)].a")
      assert {:ok, [4]} = JsonpathToAccess.lookup(data, "$.r[?(@.b == 0)].a")
      assert {:ok, [2]} = JsonpathToAccess.lookup(data, "$.r[?(@.b != 0)].a")
      assert {:ok, []} = JsonpathToAccess.lookup(data, "$.r[?(@.b > 0)].a")
      assert {:ok, [4]} = JsonpathToAccess.lookup(data, "$.r[?(@.b >= 0)].a")
      assert {:ok, [4]} = JsonpathToAccess.lookup(data, "$.r[?(@.b < 8)].a")
      assert {:ok, [4]} = JsonpathToAccess.lookup(data, "$.r[?(@.b <= 0)].a")
    end

    test "query nested" do
      data = %{
        r: [
          %{a: 1},
          %{a: 2, b: %{c: 15}},
          %{a: 3, b: %{c: 16}},
          %{a: 4, b: nil},
          %{a: 5, b: %{c: 5}}
        ]
      }

      assert {:ok, [2, 3, 5]} = JsonpathToAccess.lookup(data, "$.r[?(@.b.c)].a")
      assert {:ok, [1, 4]} = JsonpathToAccess.lookup(data, "$.r[?(!@.b.c)].a")
      assert {:ok, [2]} = JsonpathToAccess.lookup(data, "$.r[?(@.b.c == 15)].a")
      assert {:ok, [3, 5]} = JsonpathToAccess.lookup(data, "$.r[?(@.b.c != 15)].a")
      assert {:ok, [3]} = JsonpathToAccess.lookup(data, "$.r[?(@.b.c > 15)].a")
      assert {:ok, [2, 3]} = JsonpathToAccess.lookup(data, "$.r[?(@.b.c >= 15)].a")
      assert {:ok, [5]} = JsonpathToAccess.lookup(data, "$.r[?(@.b.c < 15)].a")
      assert {:ok, [2, 5]} = JsonpathToAccess.lookup(data, "$.r[?(@.b.c <= 15)].a")
      assert {:ok, [5]} = JsonpathToAccess.lookup(data, "$.r[?(@.a == @.b.c)].a")
    end

    test "absolute path" do
      data = %{
        id: 16,
        r: [
          %{a: 1},
          %{a: 2, b: %{c: 15}},
          %{a: 3, b: %{c: 16}},
          %{a: 4, b: nil},
          %{a: 5, b: %{c: 16}}
        ]
      }

      assert {:ok, [3, 5]} = JsonpathToAccess.lookup(data, "$.r[?(@.b.c == $.id)].a")
    end
  end
end
