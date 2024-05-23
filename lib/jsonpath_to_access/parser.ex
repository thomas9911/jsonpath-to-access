defmodule JsonpathToAccess.Parser do
  use Combine

  # https://github.com/stevenalexander/antlr4-jsonpath-grammar/blob/master/JsonPath.g4

  def parse(jsonpath) do
    case Combine.parse(jsonpath, parser) do
      {:error, error} -> {:error, error}
      output -> {:ok, List.flatten(output)}
    end

  end

  defp parser, do: ignore(string("$.")) |> dotnotation_expr() |> many(char(".") |> dotnotation_expr())


  def dotnotation_expr(parser \\ nil) do
    either(parser, identifierWithQualifier(), map(identifier(), & {:key, &1}))
  end

  def identifierWithQualifier(parser \\ nil) do
    parser
    |> choice([
      identifier() |> string("[]"),
      identifier() |> char("[") |> integer() |> char("]"),
      identifier() |> string("[?(") |> query_expr() |> string(")]"),
    ])
  end

  def query_expr(parser \\ nil ) do
    parser |> string("hallo this is a random string!!")
  end


  def identifier(parser \\ nil) do
    pipe(parser, [letter(), many(alphanumeric())], &Enum.join/1)
  end

  # def ws do
  #   skip_many(choice([space(), integer(), word()]))
  # end

  # INDENTIFIER : [a-zA-Z][a-zA-Z0-9]* ;
  # INT         : '0' | [1-9][0-9]* ;
  # WS  :   [ \t\n\r]+ -> skip ;

end
