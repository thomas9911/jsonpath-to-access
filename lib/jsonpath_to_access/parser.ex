defmodule JsonpathToAccess.Parser do
  use Combine

  # https://github.com/stevenalexander/antlr4-jsonpath-grammar/blob/master/JsonPath.g4

  @abitrary_large 2 ** 64

  def parse(jsonpath) do
    case Combine.parse(jsonpath, parser()) do
      {:error, error} -> {:error, error}
      output -> {:ok, List.flatten(output)}
    end
  end

  def parser do
    ignore(string("$.")) |> dotnotation_expr() |> many(char(".") |> dotnotation_expr()) |> eof()
  end

  def dotnotation_expr(parser \\ nil) do
    either(parser, identifierWithQualifier(), tagged_identifier())
  end

  def identifierWithQualifier(parser \\ nil) do
    parser
    |> choice([
      identifier() |> string("[]"),
      select_single_index(),
      select_range_index(),
      select_all_index(),
      identifier() |> string("[?(") |> query_expr() |> string(")]")
    ])
  end

  def select_single_index(parser \\ nil) do
    parser
    |> tagged_identifier()
    |> ignore(char("["))
    |> map(natural_number(), &{:select_index, &1})
    |> ignore(char("]"))
  end

  def select_range_index(parser \\ nil) do
    parser
    |> tagged_identifier()
    |> ignore(char("["))
    |> pipe(
      [
        option(natural_number()),
        ignore(char(":")),
        option(natural_number())
      ],
      fn [start, stop] ->
        {:select_range, Range.new(start || 0, (stop || @abitrary_large) - 1)}
      end
    )
    |> ignore(char("]"))
  end

  def select_all_index(parser \\ nil) do
    parser
    |> tagged_identifier()
    |> ignore(char("["))
    |> map(char("*"), &{:select_all, &1})
    |> ignore(char("]"))
  end

  def query_expr(parser \\ nil) do
    parser |> string("hallo this is a random string!!")
  end

  def tagged_identifier(parser \\ nil) do
    map(parser, identifier(), &{:key, &1})
  end

  def identifier(parser \\ nil) do
    pipe(parser, [letter(), many(alphanumeric())], &Enum.join/1)
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
