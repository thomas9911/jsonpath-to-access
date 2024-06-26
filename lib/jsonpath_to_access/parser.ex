defmodule JsonpathToAccess.Parser do
  @moduledoc """
  Implements a parser for JSONPath expressions.
  """
  use Combine

  # hack because elixir does not support infinite ranges
  @abitrary_large 2 ** 64

  def parse(jsonpath) do
    case Combine.parse(jsonpath, parser()) do
      {:error, error} ->
        {:error, error}

      output ->
        {:ok, List.flatten(output)}
    end
  end

  def parser do
    root() |> eof()
  end

  def root() do
    ignore(char("$")) |> many1(dotnotation_expr())
  end

  def dotnotation_expr(parser \\ nil) do
    parser |> either(qualifier(), tagged_identifier())
  end

  def qualifier(parser \\ nil) do
    parser
    |> choice([
      select_single_index(),
      select_multi_index(),
      select_range_index(),
      select_all_index(),
      query_expr()
    ])
  end

  def select_single_index(parser \\ nil) do
    parser
    |> between(char("["), map(natural_number(), &{:select_index, &1}), char("]"))
  end

  def select_multi_index(parser \\ nil) do
    parser
    |> map(
      between(char("["), sep_by1(natural_number(), char(",")), char("]")),
      fn indices -> {:select_multi_index, indices} end
    )
  end

  def select_range_index(parser \\ nil) do
    parser
    |> between(
      char("["),
      pipe(
        [
          option(natural_number()),
          ignore(char(":")),
          option(natural_number()),
          option(sequence([ignore(char(":")), natural_number()]))
        ],
        fn
          [start, stop, nil] ->
            {:select_range, Range.new(start || 0, (stop || @abitrary_large) - 1)}

          [start, stop, [step]] ->
            {:select_range, Range.new(start || 0, (stop || @abitrary_large) - 1, step)}
        end
      ),
      char("]")
    )
  end

  def select_all_index(parser \\ nil) do
    parser
    |> between(char("["), map(char("*"), &{:select_all, &1}), char("]"))
  end

  def query_expr(parser \\ nil) do
    parser
    |> between(string("[?("), inner_query(), string(")]"))
  end

  def inner_query(parser \\ nil) do
    parser
    |> map(
      choice([
        query_comparison(">", :greater),
        query_comparison(">=", :greater_equals),
        query_comparison("<", :lesser),
        query_comparison("<=", :lesser_equals),
        query_comparison("!=", :not_equals),
        query_comparison("==", :equals),
        query_not_contains(),
        query_contains()
      ]),
      fn data ->
        {:query, data}
      end
    )
  end

  def query_contains(parser \\ nil) do
    parser
    |> pipe(
      [relative_path()],
      fn [path] ->
        {:contains, path}
      end
    )
  end

  def query_not_contains(parser \\ nil) do
    parser
    |> pipe(
      [ignore(char("!")), relative_path()],
      fn [path] ->
        {:not_contains, path}
      end
    )
  end

  def query_comparison(parser \\ nil, text, tag) do
    parser
    |> pipe(
      [
        relative_path(),
        skip(spaces()),
        string(text),
        skip(spaces()),
        choice([
          value_literal(),
          relative_path(),
          just_absolute_path()
        ])
      ],
      fn [path, _, value] ->
        {tag, path, value}
      end
    )
  end

  def just_absolute_path(parser \\ nil) do
    parser
    |> pipe(
      [
        ignore(char("$")),
        many1(tagged_identifier())
      ],
      fn [path] -> {:absolute_path, path} end
    )
  end

  def relative_path(parser \\ nil) do
    parser
    |> pipe(
      [
        ignore(char("@")),
        many1(tagged_identifier())
      ],
      fn [path] -> {:relative_path, path} end
    )
  end

  def tagged_identifier(parser \\ nil) do
    map(
      parser,
      either(pipe([ignore(char(".")), identifier()], &Enum.at(&1, 0)), quoted_identifier()),
      &{:key, &1}
    )
  end

  def identifier(parser \\ nil) do
    pipe(parser, [letter(), many(either(alphanumeric(), char("_")))], &Enum.join/1)
  end

  def quoted_identifier(parser \\ nil) do
    parser
    |> between(string("["), string_literal(), string("]"))
  end

  def value_literal(parser \\ nil) do
    parser
    |> choice([
      string_literal(),
      natural_number()
    ])
  end

  def string_literal(parser \\ nil) do
    parser
    |> between(char("'"), map(many1(none_of(char(), ["'"])), &Enum.join/1), char("'"))
  end

  def natural_number(parser \\ nil) do
    # integer was already claimed by combine
    pipe(
      parser,
      [
        option(char("-")),
        integer()
      ],
      fn
        [nil, number] -> number
        ["-", number] -> -number
      end
    )
  end
end
