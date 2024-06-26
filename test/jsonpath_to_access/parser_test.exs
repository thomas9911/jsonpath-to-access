defmodule JsonpathToAccess.ParserTest do
  use ExUnit.Case

  test "books" do
    assert {:ok, [{:key, "books"}]} = JsonpathToAccess.Parser.parse("$.books")
  end

  test "a" do
    assert {:ok, [{:key, "a"}]} = JsonpathToAccess.Parser.parse("$.a")
  end

  test "books.author" do
    assert {:ok, [{:key, "books"}, {:key, "author"}]} =
             JsonpathToAccess.Parser.parse("$.books.author")
  end

  test "books[0].author" do
    assert {:ok, [{:key, "books"}, {:select_index, 0}, {:key, "author"}]} =
             JsonpathToAccess.Parser.parse("$.books[0].author")
  end

  test "books[1,2].author" do
    assert {:ok, [{:key, "books"}, {:select_multi_index, [1, 2]}, {:key, "author"}]} =
             JsonpathToAccess.Parser.parse("$.books[1,2].author")
  end

  test "books[1,2,4,5].author" do
    assert {:ok, [{:key, "books"}, {:select_multi_index, [1, 2, 4, 5]}, {:key, "author"}]} =
             JsonpathToAccess.Parser.parse("$.books[1,2,4,5].author")
  end

  test "books[-2].author" do
    assert {:ok, [{:key, "books"}, {:select_index, -2}, {:key, "author"}]} =
             JsonpathToAccess.Parser.parse("$.books[-2].author")
  end

  test "books[:-2].author" do
    assert {:ok, [{:key, "books"}, {:select_range, 0..-3//-1}, {:key, "author"}]} =
             JsonpathToAccess.Parser.parse("$.books[:-2].author")
  end

  test "books[:2].author" do
    assert {:ok, [{:key, "books"}, {:select_range, 0..1}, {:key, "author"}]} =
             JsonpathToAccess.Parser.parse("$.books[:2].author")
  end

  test "books[3:].author" do
    assert {:ok,
            [{:key, "books"}, {:select_range, 3..18_446_744_073_709_551_615}, {:key, "author"}]} =
             JsonpathToAccess.Parser.parse("$.books[3:].author")
  end

  test "books[:].author" do
    assert {:ok,
            [{:key, "books"}, {:select_range, 0..18_446_744_073_709_551_615}, {:key, "author"}]} =
             JsonpathToAccess.Parser.parse("$.books[:].author")
  end

  test "books[1:3].author" do
    assert {:ok, [{:key, "books"}, {:select_range, 1..2}, {:key, "author"}]} =
             JsonpathToAccess.Parser.parse("$.books[1:3].author")
  end

  test "books[*].author" do
    assert {:ok, [{:key, "books"}, {:select_all, "*"}, {:key, "author"}]} =
             JsonpathToAccess.Parser.parse("$.books[*].author")
  end

  test "books[?(@.isbn)].author" do
    assert {:ok,
            [
              {:key, "books"},
              {:query, {:contains, {:relative_path, [{:key, "isbn"}]}}},
              {:key, "author"}
            ]} = JsonpathToAccess.Parser.parse("$.books[?(@.isbn)].author")
  end

  test "books[?(!@.isbn)].author" do
    assert {:ok,
            [
              {:key, "books"},
              {:query, {:not_contains, {:relative_path, [{:key, "isbn"}]}}},
              {:key, "author"}
            ]} = JsonpathToAccess.Parser.parse("$.books[?(!@.isbn)].author")
  end

  test "books[?(@.name == 'foo')].author" do
    assert {:ok,
            [
              {:key, "books"},
              {:query, {:equals, {:relative_path, [{:key, "name"}]}, "foo"}},
              {:key, "author"}
            ]} == JsonpathToAccess.Parser.parse("$.books[?(@.name == 'foo')].author")

    assert {:ok,
            [
              {:key, "books"},
              {:query, {:equals, {:relative_path, [{:key, "name"}]}, "foo"}},
              {:key, "author"}
            ]} == JsonpathToAccess.Parser.parse("$.books[?(@.name=='foo')].author")
  end

  test "books[?(@.name != 'foo')].author" do
    assert {:ok,
            [
              {:key, "books"},
              {:query, {:not_equals, {:relative_path, [{:key, "name"}]}, "foo"}},
              {:key, "author"}
            ]} == JsonpathToAccess.Parser.parse("$.books[?(@.name != 'foo')].author")

    assert {:ok,
            [
              {:key, "books"},
              {:query, {:not_equals, {:relative_path, [{:key, "name"}]}, "foo"}},
              {:key, "author"}
            ]} == JsonpathToAccess.Parser.parse("$.books[?(@.name!='foo')].author")
  end

  test "books[?(@.id > 2)].author" do
    assert {:ok,
            [
              {:key, "books"},
              {:query, {:greater, {:relative_path, [{:key, "id"}]}, 2}},
              {:key, "author"}
            ]} == JsonpathToAccess.Parser.parse("$.books[?(@.id > 2)].author")
  end

  test "books[?(@.id >= 2)].author" do
    assert {:ok,
            [
              {:key, "books"},
              {:query, {:greater_equals, {:relative_path, [{:key, "id"}]}, 2}},
              {:key, "author"}
            ]} == JsonpathToAccess.Parser.parse("$.books[?(@.id >= 2)].author")
  end

  test "books[?(@.id < 2)].author" do
    assert {:ok,
            [
              {:key, "books"},
              {:query, {:lesser, {:relative_path, [{:key, "id"}]}, 2}},
              {:key, "author"}
            ]} == JsonpathToAccess.Parser.parse("$.books[?(@.id < 2)].author")
  end

  test "books[?(@.id <= 2)].author" do
    assert {:ok,
            [
              {:key, "books"},
              {:query, {:lesser_equals, {:relative_path, [{:key, "id"}]}, 2}},
              {:key, "author"}
            ]} == JsonpathToAccess.Parser.parse("$.books[?(@.id <= 2)].author")
  end

  test "books[?(@.id == @.remote_id)].author" do
    assert {:ok,
            [
              {:key, "books"},
              {:query,
               {:equals, {:relative_path, [{:key, "id"}]},
                {:relative_path, [{:key, "remote_id"}]}}},
              {:key, "author"}
            ]} == JsonpathToAccess.Parser.parse("$.books[?(@.id == @.remote_id)].author")
  end

  test "books[?(@.id == $.id)].author" do
    assert {:ok,
            [
              {:key, "books"},
              {:query,
               {:equals, {:relative_path, [{:key, "id"}]}, {:absolute_path, [{:key, "id"}]}}},
              {:key, "author"}
            ]} == JsonpathToAccess.Parser.parse("$.books[?(@.id == $.id)].author")
  end
end
