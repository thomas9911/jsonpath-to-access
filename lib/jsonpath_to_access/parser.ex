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
      select_range_index(),
      select_all_index()
      # string("[?(") |> query_expr() |> string(")]")
    ])
  end

  def select_single_index(parser \\ nil) do
    sequence(parser, [
      ignore(char("[")),
      map(natural_number(), &{:select_index, &1}),
      ignore(char("]"))
    ])
  end

  def select_range_index(parser \\ nil) do
    parser
    |> pipe(
      [
        ignore(char("[")),
        option(natural_number()),
        ignore(char(":")),
        option(natural_number()),
        ignore(char("]"))
      ],
      fn [start, stop] ->
        {:select_range, Range.new(start || 0, (stop || @abitrary_large) - 1)}
      end
    )
  end

  def select_all_index(parser \\ nil) do
    sequence(parser, [ignore(char("[")), map(char("*"), &{:select_all, &1}), ignore(char("]"))])
  end

  def query_expr(parser \\ nil) do
    parser |> string("hallo this is a random string!!")
  end

  def tagged_identifier(parser \\ nil) do
    map(parser, either(char(".") |> identifier(), quoted_identifier()), &{:key, &1})
  end

  def identifier(parser \\ nil) do
    pipe(parser, [letter(), many(alphanumeric())], &Enum.join/1)
  end

  def quoted_identifier(parser \\ nil) do
    pipe(
      parser,
      [
        ignore(char("[")),
        ignore(char("'")),
        # can we use word() here?
        many(none_of(char(), ["'"])),
        ignore(char("'")),
        ignore(char("]"))
      ],
      &Enum.join/1
    )
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
