defmodule JsonpathToAccess.Parser do
  use Combine

  # https://github.com/stevenalexander/antlr4-jsonpath-grammar/blob/master/JsonPath.g4

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
    ignore(char("$")) |> many1(dotnotation_expr()) |> eof()
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
      # string("[?(") |> query_expr() |> string(")]")
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
          option(natural_number())
        ],
        fn [start, stop] ->
          {:select_range, Range.new(start || 0, (stop || @abitrary_large) - 1)}
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
        relative_path()
      ]),
      fn data ->
        {:query, data}
      end
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
    pipe(parser, [letter(), many(alphanumeric())], &Enum.join/1)
  end

  def quoted_identifier(parser \\ nil) do
    parser
    |> between(string("['"), map(many(none_of(char(), ["'"])), &Enum.join/1), string("']"))
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

  # def ws do
  #   skip_many(choice([space(), integer(), word()]))
  # end

  # INDENTIFIER : [a-zA-Z][a-zA-Z0-9]* ;
  # INT         : '0' | [1-9][0-9]* ;
  # WS  :   [ \t\n\r]+ -> skip ;
end
