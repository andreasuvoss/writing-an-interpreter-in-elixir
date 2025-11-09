defmodule Evaluator do

  def define_macros(%Parser.Program{} = program, %Evaluator.Environment{} = environment) do
    macros = Enum.reject(program.statements, fn s -> 
      case s do
        %Parser.LetStatement{value: %Parser.MacroLiteral{}} -> false 
        _ -> true
      end
    end)
    statements = Enum.reject(program.statements, fn s -> 
      case s do
        %Parser.LetStatement{value: %Parser.MacroLiteral{}} -> true
        _ -> false
      end
    end)

    env = add_macros(macros, environment)

    {:ok, %{program | statements: statements}, env}
  end

  defp add_macros([%Parser.LetStatement{} = macro | tail], %Evaluator.Environment{} = environment) do
    # IO.puts("adding macro")
    # IO.inspect(macro)
    environment = add_macro(macro, environment)
    add_macros(tail, environment)
  end

  defp add_macros([], env), do: env

  defp add_macro(%Parser.LetStatement{value: %Parser.MacroLiteral{} = macro_literal} = stmt, %Evaluator.Environment{} = environment) do
    Evaluator.Environment.set(environment, stmt.name.value, %Evaluator.Macro{parameters: macro_literal.parameters, env: environment, body: macro_literal.body})
  end

  def expand_macros(%Parser.Program{} = program, %Evaluator.Environment{} = environment) do
    case Parser.Modify.modify(program, &macro_expansion_modifier(&1, environment)) do
      {:ok, %Parser.Program{} = prog} -> {:ok, prog}
      {:error, error} -> {:error, create_error(error)}
    end
  end

  defp macro_expansion_modifier(node, environment) do
    with %Parser.CallExpression{function: %Parser.Identifier{} = ident} = call_exp <- node,
         {:ok, %Evaluator.Macro{} = macro} <- look_for_macro(ident, environment),
         args = quote_args(call_exp.arguments),
         eval_env = extend_macro_env(macro, args),
         {:ok, quoted, _env} <- eval(macro.body, eval_env)
      do
        {:ok, quoted.node}
    else
      ^node -> {:ok, node}
      :not_found -> {:ok, node}
      {:error, error} -> {:error, error}
    end
  end

  defp look_for_macro(ident, macro_env) do
    case Evaluator.Environment.get(macro_env, ident.value) do
      {:ok, %Evaluator.Macro{} = macro} -> {:ok, macro}
      {:error, _} -> :not_found
    end
  end

  defp quote_args(args) do
    Enum.map(args, fn a -> %Evaluator.Quote{node: a} end)
  end

  defp extend_macro_env(macro, args) do
    internal_store = 
      macro.parameters
      |> Enum.with_index(0) 
      |> Enum.map(fn {param, index} -> {param.value, Enum.at(args, index)} end) 
      |> Map.new()

    %Evaluator.Environment{store: internal_store, outer: nil}
  end

  defp quote_node(node, environment) do
    case eval_unquote_calls(node, environment) do
      {:ok, node} -> {:ok, %Evaluator.Quote{node: node}}
    end
  end

  defp eval_unquote_calls(node, environment) do
    Parser.Modify.modify(node, fn n -> 
      with %Parser.CallExpression{function: %Parser.Identifier{token: %Lexer.Token{literal: "unquote"}}} <- n,
           {:ok, ret, _} <- eval(Enum.at(n.arguments, 0), environment) 
      do
        {:ok, convert_to_ast_node(ret)}
      else
        ^n -> {:ok, n} 
      end
    end)
  end

  defp convert_to_ast_node(object) do
    case object do
      %Evaluator.Integer{} = int -> %Parser.IntegerLiteral{token: %Lexer.Token{type: :int, literal: "#{int}"}, value: int.value}
      %Evaluator.Boolean{value: true} -> %Parser.Boolean{token: %Lexer.Token{type: :true, literal: "true"}, value: true}
      %Evaluator.Boolean{value: false} -> %Parser.Boolean{token: %Lexer.Token{type: :false, literal: "false"}, value: false}
      %Evaluator.Quote{} -> object.node
    end
  end

  def eval(%Parser.Program{} = program, %Evaluator.Environment{} = environment) do
    case eval_program(program.statements, environment) do
      {:ok, result, env} -> {:ok, result, env}
      {:error, error} -> {:error, error}
    end
  end

  def eval(%Parser.ExpressionStatement{} = expression_statement, %Evaluator.Environment{} = environment) do
    eval(expression_statement.expression, environment)
  end

  def eval(%Parser.BlockStatement{statements: statements}, %Evaluator.Environment{} = environment) do
    eval_block_statements(statements, environment)
  end

  def eval(%Parser.ReturnStatement{return_value: return_value}, %Evaluator.Environment{} = environment) do
    case eval(return_value, environment) do
       {:ok, value, env} -> {:ok, %Evaluator.Return{value: value}, env}
       {:error, error} -> {:error, error}
    end
  end

  def eval(%Parser.IfExpression{} = expr, %Evaluator.Environment{} = environment) do
    with {:ok, condition, env} <- eval(expr.condition, environment) do
      case {is_truthy?(condition), expr.alternative} do
        {true, _} -> eval(expr.consequence, env)
        {false, nil} -> {:ok, %Evaluator.Null{}, env}
        {false, alternative} -> eval(alternative, env)
      end
    else
      {:error, error} -> {:error, error}
    end
  end

  def eval(%Parser.IntegerLiteral{} = integer, %Evaluator.Environment{} = environment) do
    {:ok, %Evaluator.Integer{value: integer.value}, environment}
  end

  def eval(%Parser.StringLiteral{} = string, %Evaluator.Environment{} = environment) do
    {:ok, %Evaluator.String{value: string.value}, environment}
  end

  def eval(%Parser.Boolean{} = bool, %Evaluator.Environment{} = environment) do
    {:ok, %Evaluator.Boolean{value: bool.value}, environment}
  end

  def eval(%Parser.PrefixExpression{} = expr, %Evaluator.Environment{} = environment) do
    case eval(expr.right, environment) do
      {:ok, right, env} -> eval_prefix_expression(expr.operator, right, env)
      {:error, error} -> {:error, error}
    end
  end

  def eval(%Parser.InfixExpression{} = expr, %Evaluator.Environment{} = environment) do
    with {:ok, left, env} <- eval(expr.left, environment),
         {:ok, right, env} <- eval(expr.right, env) 
    do
      eval_infix_expression(expr.operator, left, right, env)
    else
      {:error, error} -> {:error, error}
    end
  end

  def eval(%Parser.Identifier{} = identifier, %Evaluator.Environment{} = environment) do
    case Evaluator.Environment.get(environment, identifier.value) do
        {:ok, val} -> {:ok, val, environment}
        {:error, _} -> case get_builtin(identifier) do
          {:ok, val} -> {:ok, val, environment}
          {:error, error} ->{:error, create_error(error)}
      end
    end
  end

  def eval(%Parser.LetStatement{value: %Parser.FunctionLiteral{} = literal} = stmt, %Evaluator.Environment{} = environment) do
    name = stmt.name.token.literal
    case eval(literal, environment) do
      {:ok, fun, _}  -> {:ok, %{fun | name: name}, Evaluator.Environment.set(environment, name, %{fun | name: name})}
    end
  end

  def eval(%Parser.LetStatement{} = stmt, %Evaluator.Environment{} = environment) do
    case eval(stmt.value, environment) do
      {:ok, value, %Evaluator.Environment{} = env} -> {:ok, value, Evaluator.Environment.set(env, stmt.name.value, value)}
      {:error, error} -> {:error, error}
    end
  end

  def eval(%Parser.HashLiteral{} = hash, %Evaluator.Environment{} = environment) do
    {:ok, %Evaluator.Hash{pairs: Map.new(hash.pairs, fn {k, v} -> 
      case eval(k, environment) do
        {:ok, key, env} -> case eval(v, env) do
          {:ok, value, _} -> {key, value}
        end
      end
    end)}, environment}
  end

  def eval(%Parser.FunctionLiteral{} = function, %Evaluator.Environment{} = environment) do
    {:ok, %Evaluator.Function{parameters: function.parameters, body: function.body, env: environment}, environment}
  end

  def eval(%Parser.CallExpression{} = call_expression, %Evaluator.Environment{} = environment) do
    case call_expression.function.token.literal do
      "quote" -> case length(call_expression.arguments) do 
        1 -> case quote_node(Enum.at(call_expression.arguments, 0), environment) do
          {:ok, node} -> {:ok, node, environment}
          {:error, _} = err -> err
        end
        arg_length -> {:error, create_error("quote only accepts 1 argument got #{arg_length}")}
      end
      _ -> case eval(call_expression.function, environment) do
      {:ok, function, env} -> case eval_expressions(call_expression.arguments, env) do
        {:ok, args, env} -> apply_function(function, args, env)
        {:error, error} -> {:error, error}
      end
      {:error, error} -> {:error, error}
    end
    end
    
  end


  def eval(%Parser.ArrayLiteral{} = array, %Evaluator.Environment{} = environment) do
    case eval_expressions(array.elements, environment) do
      {:ok, exprs, env} -> {:ok, %Evaluator.Array{elements: exprs}, env}
      {:error, error} -> {:error, error}
    end
  end

  def eval(%Parser.IndexExpression{} = index_expr, %Evaluator.Environment{} = environment) do
    case eval(index_expr.left, environment) do
      {:ok, left, env} -> case eval(index_expr.index, env) do
        {:ok, index, env} -> case {left, index} do
          {%Evaluator.Array{}, %Evaluator.Integer{}} ->
            idx = index.value
            max = length(left.elements) - 1

            if idx < 0 || idx > max do
              {:ok, %Evaluator.Null{}, env}
            else
              {:ok, Enum.at(left.elements, idx), env}
            end
          {%Evaluator.Hash{}, key} ->

            case key do
              %Evaluator.Integer{} -> handle_key(left, key, env)
              %Evaluator.String{} -> handle_key(left, key, env)
              %Evaluator.Boolean{} -> handle_key(left, key, env)
              _ -> {:error, create_error("unsupported index type: #{Evaluator.Object.type(key)}")}
            end
        {:error, error} -> {:error, error}
        end
        {:error, error} -> {:error, error}
      end
      {:error, error} -> {:error, error}
    end
  end

  defp handle_key(left, key, env) do
    case {left.pairs[key], env} do
      {nil, env} -> {:ok, %Evaluator.Null{}, env}
      {val, env} -> {:ok, val, env}
    end
  end

  defp get_builtin(%Parser.Identifier{} = identifier) do
    case identifier.value do
      "len" -> {:ok, %Evaluator.Builtin{fn: fn [head | _] = args -> 
        if length(args) != 1 do
          {:error, create_error("wrong number of arguments got #{length(args)} want 1")}
        else
          case head do
            %Evaluator.String{} -> {:ok, %Evaluator.Integer{value: String.length(head.value)}}
            %Evaluator.Array{} -> {:ok, %Evaluator.Integer{value: length(head.elements)}}
            obj -> {:error, create_error("argument to `len` not supported, got #{Evaluator.Object.type(obj)}")}
          end
        end
      end}}
      "first" -> {:ok, %Evaluator.Builtin{fn: fn [head | _] = args -> 
        if length(args) != 1 do
          {:error, create_error("wrong number of arguments got #{length(args)} want 1")}
        else
          case head do
            %Evaluator.Array{elements: [head | _]} -> {:ok, head}
            %Evaluator.Array{elements: []} -> {:ok, %Evaluator.Null{}}
            obj -> {:error, create_error("argument to `first` not supported, got #{Evaluator.Object.type(obj)} must be ARRAY")}
          end
        end
      end}}
      "last" -> {:ok, %Evaluator.Builtin{fn: fn [head | _] = args -> 
        if length(args) != 1 do
          {:error, create_error("wrong number of arguments got #{length(args)} want 1")}
        else
          case head do
            %Evaluator.Array{elements: [head | tail]} -> {:ok, Enum.at([head | tail], length([head | tail])-1)}
            %Evaluator.Array{elements: []} -> {:ok, %Evaluator.Null{}}
            obj -> {:error, create_error("argument to `last` not supported, got #{Evaluator.Object.type(obj)} must be ARRAY")}
          end
        end
      end}}
      "rest" -> {:ok, %Evaluator.Builtin{fn: fn [head | _] = args -> 
        if length(args) != 1 do
          {:error, create_error("wrong number of arguments got #{length(args)} want 1")}
        else
          case head do
            %Evaluator.Array{elements: [_ | tail]} -> {:ok, %Evaluator.Array{elements: tail}}
            %Evaluator.Array{elements: []} -> {:ok, %Evaluator.Null{}}
            obj -> {:error, create_error("argument to `rest` not supported, got #{Evaluator.Object.type(obj)} must be ARRAY")}
          end
        end
      end}}
      "push" -> {:ok, %Evaluator.Builtin{fn: fn [obj, val | _] = args -> 
        if length(args) != 2 do
          {:error, create_error("wrong number of arguments got #{length(args)} want 2")}
        else
          case obj do
            %Evaluator.Array{elements: elements} -> {:ok, %Evaluator.Array{elements: elements ++ [val] }}
            obj -> {:error, create_error("argument to `rest` not supported, got #{Evaluator.Object.type(obj)} must be ARRAY")}
          end
        end
      end}}
      "puts" -> {:ok, %Evaluator.Builtin{fn: fn args -> 
        Enum.each(args, fn x -> 
          case x do
            %Evaluator.String{} -> IO.puts(String.slice("#{x}", 1..-2//1))
            _ -> IO.puts(x)
          end
        end)
        {:ok, %Evaluator.Null{}}
      end}}
      _ -> {:error, "identifier not found: #{identifier.token.literal}"}
    end
  end

  defp apply_function(%Evaluator.Function{} = function, args, %Evaluator.Environment{} = environment) do
    case extend_function_env(function, args) do
      {:ok, extended_env} -> 
        case eval(function.body, extended_env) do
          {:ok, %Evaluator.Return{} = ret, _} -> {:ok, ret.value, environment}
          {:ok, val, _} -> {:ok, val, environment}
        end
      {:error, error} -> {:error, error}
    end
  end

  defp apply_function(%Evaluator.Builtin{} = builtin, args, %Evaluator.Environment{} = environment) do
    case length(args) do
       0 -> {:error, create_error("please provide arguments for builtin")}
       _ -> case builtin.fn.(args) do
         {:ok, val} -> {:ok, val, environment}
         {:error, error} -> {:error, error}
       end
    end
  end

  defp extend_function_env(%Evaluator.Function{} = function, args) do
    if length(function.parameters) != length(args) do
      {:error, create_error("wrong number of arguments passed to the function #{function.name}")}
    else
      internal_store = 
        function.parameters 
        |> Enum.with_index(0) 
        |> Enum.map(fn {param, index} -> {param.value, Enum.at(args, index)} end) 
        |> Map.new()
        |> maybe_add_self(function)
      {:ok, %Evaluator.Environment{store: internal_store, outer: function.env}}
    end

  end

  # Helpers for allowing recursion by adding the function itself to its own environment
  defp maybe_add_self(store, %Evaluator.Function{name: nil}), do: store
  defp maybe_add_self(store, %Evaluator.Function{name: name} = fun), do: Map.put(store, name, fun)

  defp eval_expressions(_, acc \\ [], _)
  defp eval_expressions([expression | tail], acc, %Evaluator.Environment{} = environment) do
    case eval(expression, environment) do
      {:ok, value, env} -> eval_expressions(tail, [value | acc], env)
      {:error, error} -> {:error, error}
    end
  end
  defp eval_expressions([expression], acc, %Evaluator.Environment{} = environment) do
    case eval(expression, environment) do
      {:ok, value, env} -> {:ok, Enum.reverse([value | acc]), env}
    end
  end
  defp eval_expressions([], acc, environment), do: {:ok, Enum.reverse(acc), environment}

  defp is_truthy?(value) do
    case value do
      %Evaluator.Null{} -> false
      %Evaluator.Boolean{value: true} -> true
      %Evaluator.Boolean{value: false} -> false
      _ -> true
    end
  end

  defp eval_infix_expression("+", %Evaluator.Integer{} = left, %Evaluator.Integer{} = right, %Evaluator.Environment{} = environment) do
    {:ok, %Evaluator.Integer{value: left.value + right.value}, environment}
  end

  defp eval_infix_expression("-", %Evaluator.Integer{} = left, %Evaluator.Integer{} = right, %Evaluator.Environment{} = environment) do
    {:ok, %Evaluator.Integer{value: left.value - right.value}, environment}
  end

  defp eval_infix_expression("*", %Evaluator.Integer{} = left, %Evaluator.Integer{} = right, %Evaluator.Environment{} = environment) do
    {:ok, %Evaluator.Integer{value: left.value * right.value}, environment}
  end

  defp eval_infix_expression("/", %Evaluator.Integer{} = left, %Evaluator.Integer{} = right, %Evaluator.Environment{} = environment) do
    {:ok, %Evaluator.Integer{value: trunc(left.value / right.value)}, environment}
  end

  defp eval_infix_expression(">", %Evaluator.Integer{} = left, %Evaluator.Integer{} = right, %Evaluator.Environment{} = environment) do
    {:ok, %Evaluator.Boolean{value: left.value > right.value}, environment}
  end

  defp eval_infix_expression("<", %Evaluator.Integer{} = left, %Evaluator.Integer{} = right, %Evaluator.Environment{} = environment) do
    {:ok, %Evaluator.Boolean{value: left.value < right.value}, environment}
  end

  defp eval_infix_expression("==", %Evaluator.Integer{} = left, %Evaluator.Integer{} = right, %Evaluator.Environment{} = environment) do
    {:ok, %Evaluator.Boolean{value: left.value == right.value}, environment}
  end

  defp eval_infix_expression("!=", %Evaluator.Integer{} = left, %Evaluator.Integer{} = right, %Evaluator.Environment{} = environment) do
    {:ok, %Evaluator.Boolean{value: left.value != right.value}, environment}
  end

  defp eval_infix_expression("==", %Evaluator.Boolean{} = left, %Evaluator.Boolean{} = right, %Evaluator.Environment{} = environment) do
    {:ok, %Evaluator.Boolean{value: left.value == right.value}, environment}
  end

  defp eval_infix_expression("!=", %Evaluator.Boolean{} = left, %Evaluator.Boolean{} = right, %Evaluator.Environment{} = environment) do
    {:ok, %Evaluator.Boolean{value: left.value != right.value}, environment}
  end

  defp eval_infix_expression("+", %Evaluator.String{} = left, %Evaluator.String{} = right, %Evaluator.Environment{} = environment) do
    {:ok, %Evaluator.String{value: left.value <> right.value}, environment}
  end

  defp eval_infix_expression("!=", %Evaluator.String{} = left, %Evaluator.String{} = right, %Evaluator.Environment{} = environment) do
    {:ok, %Evaluator.Boolean{value: left.value != right.value}, environment}
  end

  defp eval_infix_expression("==", %Evaluator.String{} = left, %Evaluator.String{} = right, %Evaluator.Environment{} = environment) do
    {:ok, %Evaluator.Boolean{value: left.value == right.value}, environment}
  end


  defp eval_infix_expression(operator, left, right, %Evaluator.Environment{} = _) do
    if Evaluator.Object.type(left) != Evaluator.Object.type(right) do
      {:error, create_error("type mismatch: #{Evaluator.Object.type(left)} #{operator} #{Evaluator.Object.type(right)}")}
    else
      {:error, create_error("unknown operator: #{Evaluator.Object.type(left)} #{operator} #{Evaluator.Object.type(right)}")}
    end
  end

  defp eval_prefix_expression("!", right, %Evaluator.Environment{} = environment) do
    case right do
      %Evaluator.Boolean{value: true} -> {:ok, %Evaluator.Boolean{value: false}, environment}
      %Evaluator.Boolean{value: false} -> {:ok, %Evaluator.Boolean{value: true}, environment}
      %Evaluator.Null{} -> {:ok, %Evaluator.Boolean{value: true}, environment}
      _ -> {:ok, %Evaluator.Boolean{value: false}, environment}
    end
  end

  defp eval_prefix_expression("-", %Evaluator.Integer{value: val}, %Evaluator.Environment{} = environment) do
    {:ok, %Evaluator.Integer{value: -val}, environment}
  end

  defp eval_prefix_expression(operator, right, %Evaluator.Environment{} = _) do
    {:error, create_error("unknown operator: #{operator}#{Evaluator.Object.type(right)}")}
  end

  defp eval_program([statement], %Evaluator.Environment{} = environment) do
    case eval(statement, environment) do
      {:ok, %Evaluator.Return{value: value}, env} -> {:ok, value, env}
      {:ok, value, env} -> {:ok, value, env}
      {:error, error} -> {:error, error}
    end
  end

  defp eval_program([], %Evaluator.Environment{} = environment) do
      {:ok, nil, environment}
  end

  defp eval_program([statement | tail], %Evaluator.Environment{} = environment) do
    case eval(statement, environment) do
      {:ok, %Evaluator.Return{value: value}, env} -> {:ok, value, env}
      {:error, error} -> {:error, error}
      {:ok, _, env} -> eval_program(tail, env)
    end
  end

  defp eval_block_statements([statement], %Evaluator.Environment{} = environment) do
    eval(statement, environment)
  end
  
  defp eval_block_statements([statement | tail], %Evaluator.Environment{} = environment) do
    case eval(statement, environment) do
      {:ok, %Evaluator.Return{} = value, env} -> {:ok, value, env}
      {:error, error} -> {:error, error}
      {:ok, _, env} -> eval_block_statements(tail, env)
    end
  end

  defp eval_block_statements([], %Evaluator.Environment{} = environment) do
    {:ok, %Evaluator.Null{}, environment}
  end

  defp create_error(message) do
    %Evaluator.Error{message: "ERROR: #{message}"}
  end
end

# let map = fn(arr, f) { let iter = fn(arr, acc) { if (len(arr) == 0) { acc } else { iter(rest(arr), push(acc, f(first(arr))))}} iter(arr, [])};
# let reduce = fn(arr, initial, f) { let iter = fn(arr, result) { if(len(arr)==0) { result} else { iter(rest(arr), f(result, first(arr)))}}iter(arr, initial)}
# let sum = fn(arr) { reduce(arr, 0, fn(initial, el) {initial + el})}
# let counter = fn(x) { if (x > 100 ) {return true; } else { let foobar = 9999; counter(x+1) } };
