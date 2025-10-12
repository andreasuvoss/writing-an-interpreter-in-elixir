defmodule Lexer.Lexer do
  alias Lexer.Token

  defp is_letter(nil), do: false

  defp is_letter(char) do
    ("a" <= char && char <= "z") || ("A" <= char && char <= "Z") || char == "_"
  end

  defp is_digit(nil), do: false

  defp is_digit(char) do
    "0" <= char && char <= "9"
  end

  def read_identifier(input, i \\ 1) do
    char = String.at(input, i)

    if is_letter(char) do
      read_identifier(input, i + 1)
    else
      i - 1
    end
  end

  def read_number(input, i \\ 1) do
    char = String.at(input, i)

    if is_digit(char) do
      read_number(input, i + 1)
    else
      i - 1
    end
  end

  def get_token(input) do
    # Consume whitespace
    input = String.trim_leading(input)
    char = input |> String.at(0)

    cond do
      is_letter(char) ->
        idx = read_identifier(input)
        ident = String.slice(input, 0..idx)
        token = Token.lookup_identifier(ident)
        new_token(token.type, token.literal, input)

      is_digit(char) ->
        idx = read_number(input)
        value = String.slice(input, 0..idx)
        new_token(:int, value, input)

      true ->
        case char do
          "=" ->
            peeked_char = input |> String.at(1)

            if peeked_char == "=" do
              new_token(:eq, char <> peeked_char, input)
            else
              new_token(:assign, char, input)
            end

          "+" ->
            new_token(:plus, char, input)

          "(" ->
            new_token(:lparen, char, input)

          ")" ->
            new_token(:rparen, char, input)

          "{" ->
            new_token(:lbrace, char, input)

          "}" ->
            new_token(:rbrace, char, input)

          "," ->
            new_token(:comma, char, input)

          ";" ->
            new_token(:semicolon, char, input)

          "-" ->
            new_token(:minus, char, input)

          "/" ->
            new_token(:slash, char, input)

          "<" ->
            new_token(:lt, char, input)

          ">" ->
            new_token(:gt, char, input)

          "*" ->
            new_token(:asterix, char, input)

          "!" ->
            peeked_char = input |> String.at(1)

            if peeked_char == "=" do
              new_token(:not_eq, char <> peeked_char, input)
            else
              new_token(:bang, char, input)
            end

          nil ->
            new_token(:eof, nil, input)

          x ->
            new_token(:illegal, x, input)
        end
    end
  end

  defp new_token(:eof, _, _), do: {%{type: :eof, literal: ""}, nil}

  defp new_token(type, literal, input) do
    literal_length = String.length(literal)
    {%{type: type, literal: literal}, String.slice(input, literal_length..String.length(input))}
  end

  def tokenize(input) do
    {tok, rest} = get_token(input)
    if tok.type == :eof, do: [tok], else: [tok | tokenize(rest)]
  end
end

# Notes / rubbish

# true ->
#   case {char, char1} do
#     # {"=", "="} ->
#     #   new_token(:eq, char<>char1, input)
#     # {"!", "="} ->
#     #   new_token(:not_eq, char<>char1, input)
#
#     {"=", _} ->
#       peeked_char = input |> String.at(1)
#       if peeked_char == "=" do
#         new_token(:eq, char<>peeked_char, input)
#       else
#         new_token(:assign, char, input)
#       end
#     {"+", _} ->
#       new_token(:plus, char, input)
#
#     {"(", _} ->
#       new_token(:lparen, char, input)
#
#     {")", _} ->
#       new_token(:rparen, char, input)
#
#     {"{", _} ->
#       new_token(:lbrace, char, input)
#
#     {"}", _} ->
#       new_token(:rbrace, char, input)
#
#     {",", _} ->
#       new_token(:comma, char, input)
#
#     {";", _} ->
#       new_token(:semicolon, char, input)
#
#     {"-", _} ->
#       new_token(:minus, char, input)
#
#     {"/", _} ->
#       new_token(:slash, char, input)
#
#     {"<", _} ->
#       new_token(:lt, char, input)
#
#     {">", _} ->
#       new_token(:gt, char, input)
#
#     {"*", _} ->
#       new_token(:asterix, char, input)
#
#     {"!", _} ->
#       peeked_char = input |> String.at(1)
#       if peeked_char == "=" do
#         new_token(:not_eq, char<>peeked_char, input)
#       else
#         new_token(:bang, char, input)
#       end
#
#     {nil, nil} ->
#       new_token(:eof, nil, input)
#
#     {x, _} ->
#       new_token(:illegal, x, input)
#   end
