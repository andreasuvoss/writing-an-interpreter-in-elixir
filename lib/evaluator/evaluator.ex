defmodule Evaluator do
  def define_macros(%AST.Program{} = program, %Object.Environment{} = environment) do
    macros = Enum.reject(program.statements, fn s -> 
      case s do
        %AST.LetStatement{value: %AST.MacroLiteral{}} -> false 
        _ -> true
      end
    end)
    statements = Enum.reject(program.statements, fn s -> 
      case s do
        %AST.LetStatement{value: %AST.MacroLiteral{}} -> true
        _ -> false
      end
    end)

    env = add_macros(macros, environment)

    {:ok, %{program | statements: statements}, env}
  end

  defp add_macros([%AST.LetStatement{} = macro | tail], %Object.Environment{} = environment) do
    environment = add_macro(macro, environment)
    add_macros(tail, environment)
  end

  defp add_macros([], env), do: env

  defp add_macro(%AST.LetStatement{value: %AST.MacroLiteral{} = macro_literal} = stmt, %Object.Environment{} = environment) do
    Object.Environment.set(environment, stmt.name.value, %Object.Macro{parameters: macro_literal.parameters, env: environment, body: macro_literal.body})
  end

  def expand_macros(%AST.Program{} = program, %Object.Environment{} = environment) do
    case Parser.Modify.modify(program, &macro_expansion_modifier(&1, environment)) do
      {:ok, %AST.Program{} = prog} -> {:ok, prog}
      {:error, error} -> {:error, create_error(error)}
    end
  end

  defp macro_expansion_modifier(node, environment) do
    with %AST.CallExpression{function: %AST.Identifier{} = ident} = call_exp <- node,
         {:ok, %Object.Macro{} = macro} <- look_for_macro(ident, environment),
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
    case Object.Environment.get(macro_env, ident.value) do
      {:ok, %Object.Macro{} = macro} -> {:ok, macro}
      {:error, _} -> :not_found
    end
  end

  defp quote_args(args) do
    Enum.map(args, fn a -> %Object.Quote{node: a} end)
  end

  defp extend_macro_env(macro, args) do
    internal_store = 
      macro.parameters
      |> Enum.with_index(0) 
      |> Enum.map(fn {param, index} -> {param.value, Enum.at(args, index)} end) 
      |> Map.new()

    %Object.Environment{store: internal_store, outer: nil}
  end

  defp quote_node(node, environment) do
    case eval_unquote_calls(node, environment) do
      {:ok, node} -> {:ok, %Object.Quote{node: node}}
    end
  end

  defp eval_unquote_calls(node, environment) do
    Parser.Modify.modify(node, fn n -> 
      with %AST.CallExpression{function: %AST.Identifier{token: %Lexer.Token{literal: "unquote"}}} <- n,
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
      %Object.Integer{} = int -> %AST.IntegerLiteral{token: %Lexer.Token{type: :int, literal: "#{int}"}, value: int.value}
      %Object.Boolean{value: true} -> %AST.Boolean{token: %Lexer.Token{type: :true, literal: "true"}, value: true}
      %Object.Boolean{value: false} -> %AST.Boolean{token: %Lexer.Token{type: :false, literal: "false"}, value: false}
      %Object.Quote{} -> object.node
    end
  end

  def eval(%AST.Program{} = program, %Object.Environment{} = environment) do
    case eval_program(program.statements, environment) do
      {:ok, result, env} -> {:ok, result, env}
      {:error, error} -> {:error, error}
    end
  end

  def eval(%AST.ExpressionStatement{} = expression_statement, %Object.Environment{} = environment) do
    eval(expression_statement.expression, environment)
  end

  def eval(%AST.BlockStatement{statements: statements}, %Object.Environment{} = environment) do
    eval_block_statements(statements, environment)
  end

  def eval(%AST.ReturnStatement{return_value: return_value}, %Object.Environment{} = environment) do
    case eval(return_value, environment) do
       {:ok, value, env} -> {:ok, %Object.Return{value: value}, env}
       {:error, error} -> {:error, error}
    end
  end

  def eval(%AST.IfExpression{} = expr, %Object.Environment{} = environment) do
    with {:ok, condition, env} <- eval(expr.condition, environment) do
      case {is_truthy?(condition), expr.alternative} do
        {true, _} -> eval(expr.consequence, env)
        {false, nil} -> {:ok, %Object.Null{}, env}
        {false, alternative} -> eval(alternative, env)
      end
    else
      {:error, error} -> {:error, error}
    end
  end

  def eval(%AST.IntegerLiteral{} = integer, %Object.Environment{} = environment) do
    {:ok, %Object.Integer{value: integer.value}, environment}
  end

  def eval(%AST.StringLiteral{} = string, %Object.Environment{} = environment) do
    {:ok, %Object.String{value: string.value}, environment}
  end

  def eval(%AST.Boolean{} = bool, %Object.Environment{} = environment) do
    {:ok, %Object.Boolean{value: bool.value}, environment}
  end

  def eval(%AST.PrefixExpression{} = expr, %Object.Environment{} = environment) do
    case eval(expr.right, environment) do
      {:ok, right, env} -> eval_prefix_expression(expr.operator, right, env)
      {:error, error} -> {:error, error}
    end
  end

  def eval(%AST.InfixExpression{} = expr, %Object.Environment{} = environment) do
    with {:ok, left, env} <- eval(expr.left, environment),
         {:ok, right, env} <- eval(expr.right, env) 
    do
      eval_infix_expression(expr.operator, left, right, env)
    else
      {:error, error} -> {:error, error}
    end
  end

  def eval(%AST.Identifier{} = identifier, %Object.Environment{} = environment) do
    case Object.Environment.get(environment, identifier.value) do
        {:ok, val} -> {:ok, val, environment}
        {:error, _} -> case get_builtin(identifier) do
          {:ok, val} -> {:ok, val, environment}
          {:error, error} ->{:error, create_error(error)}
      end
    end
  end

  def eval(%AST.LetStatement{value: %AST.FunctionLiteral{} = literal} = stmt, %Object.Environment{} = environment) do
    name = stmt.name.token.literal
    case eval(literal, environment) do
      {:ok, fun, _}  -> {:ok, %{fun | name: name}, Object.Environment.set(environment, name, %{fun | name: name})}
    end
  end

  def eval(%AST.LetStatement{} = stmt, %Object.Environment{} = environment) do
    case eval(stmt.value, environment) do
      {:ok, value, %Object.Environment{} = env} -> {:ok, value, Object.Environment.set(env, stmt.name.value, value)}
      {:error, error} -> {:error, error}
    end
  end

  def eval(%AST.HashLiteral{} = hash, %Object.Environment{} = environment) do
    {:ok, %Object.Hash{pairs: Map.new(hash.pairs, fn {k, v} -> 
      case eval(k, environment) do
        {:ok, key, env} -> case eval(v, env) do
          {:ok, value, _} -> {key, value}
        end
      end
    end)}, environment}
  end

  def eval(%AST.FunctionLiteral{} = function, %Object.Environment{} = environment) do
    {:ok, %Object.Function{parameters: function.parameters, body: function.body, env: environment}, environment}
  end

  def eval(%AST.CallExpression{} = call_expression, %Object.Environment{} = environment) do
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


  def eval(%AST.ArrayLiteral{} = array, %Object.Environment{} = environment) do
    case eval_expressions(array.elements, environment) do
      {:ok, exprs, env} -> {:ok, %Object.Array{elements: exprs}, env}
      {:error, error} -> {:error, error}
    end
  end

  def eval(%AST.IndexExpression{} = index_expr, %Object.Environment{} = environment) do
    case eval(index_expr.left, environment) do
      {:ok, left, env} -> case eval(index_expr.index, env) do
        {:ok, index, env} -> case {left, index} do
          {%Object.Array{}, %Object.Integer{}} ->
            idx = index.value
            max = length(left.elements) - 1

            if idx < 0 || idx > max do
              {:ok, %Object.Null{}, env}
            else
              {:ok, Enum.at(left.elements, idx), env}
            end
          {%Object.Hash{}, key} ->

            case key do
              %Object.Integer{} -> handle_key(left, key, env)
              %Object.String{} -> handle_key(left, key, env)
              %Object.Boolean{} -> handle_key(left, key, env)
              _ -> {:error, create_error("unsupported index type: #{Object.Object.type(key)}")}
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
      {nil, env} -> {:ok, %Object.Null{}, env}
      {val, env} -> {:ok, val, env}
    end
  end

  defp get_builtin(%AST.Identifier{} = identifier) do
    case identifier.value do
      "len" -> {:ok, %Object.Builtin{fn: fn [head | _] = args -> 
        if length(args) != 1 do
          {:error, create_error("wrong number of arguments got #{length(args)} want 1")}
        else
          case head do
            %Object.String{} -> {:ok, %Object.Integer{value: String.length(head.value)}}
            %Object.Array{} -> {:ok, %Object.Integer{value: length(head.elements)}}
            obj -> {:error, create_error("argument to `len` not supported, got #{Object.Object.type(obj)}")}
          end
        end
      end}}
      "first" -> {:ok, %Object.Builtin{fn: fn [head | _] = args -> 
        if length(args) != 1 do
          {:error, create_error("wrong number of arguments got #{length(args)} want 1")}
        else
          case head do
            %Object.Array{elements: [head | _]} -> {:ok, head}
            %Object.Array{elements: []} -> {:ok, %Object.Null{}}
            obj -> {:error, create_error("argument to `first` not supported, got #{Object.Object.type(obj)} must be ARRAY")}
          end
        end
      end}}
      "last" -> {:ok, %Object.Builtin{fn: fn [head | _] = args -> 
        if length(args) != 1 do
          {:error, create_error("wrong number of arguments got #{length(args)} want 1")}
        else
          case head do
            %Object.Array{elements: [head | tail]} -> {:ok, Enum.at([head | tail], length([head | tail])-1)}
            %Object.Array{elements: []} -> {:ok, %Object.Null{}}
            obj -> {:error, create_error("argument to `last` not supported, got #{Object.Object.type(obj)} must be ARRAY")}
          end
        end
      end}}
      "rest" -> {:ok, %Object.Builtin{fn: fn [head | _] = args -> 
        if length(args) != 1 do
          {:error, create_error("wrong number of arguments got #{length(args)} want 1")}
        else
          case head do
            %Object.Array{elements: [_ | tail]} -> {:ok, %Object.Array{elements: tail}}
            %Object.Array{elements: []} -> {:ok, %Object.Null{}}
            obj -> {:error, create_error("argument to `rest` not supported, got #{Object.Object.type(obj)} must be ARRAY")}
          end
        end
      end}}
      "push" -> {:ok, %Object.Builtin{fn: fn [obj, val | _] = args -> 
        if length(args) != 2 do
          {:error, create_error("wrong number of arguments got #{length(args)} want 2")}
        else
          case obj do
            %Object.Array{elements: elements} -> {:ok, %Object.Array{elements: elements ++ [val] }}
            obj -> {:error, create_error("argument to `rest` not supported, got #{Object.Object.type(obj)} must be ARRAY")}
          end
        end
      end}}
      "puts" -> {:ok, %Object.Builtin{fn: fn args -> 
        Enum.each(args, fn x -> 
          case x do
            %Object.String{} -> IO.puts(String.slice("#{x}", 1..-2//1))
            _ -> IO.puts(x)
          end
        end)
        {:ok, %Object.Null{}}
      end}}
      _ -> {:error, "identifier not found: #{identifier.token.literal}"}
    end
  end

  defp apply_function(%Object.Function{} = function, args, %Object.Environment{} = environment) do
    case extend_function_env(function, args) do
      {:ok, extended_env} -> 
        case eval(function.body, extended_env) do
          {:ok, %Object.Return{} = ret, _} -> {:ok, ret.value, environment}
          {:ok, val, _} -> {:ok, val, environment}
        end
      {:error, error} -> {:error, error}
    end
  end

  defp apply_function(%Object.Builtin{} = builtin, args, %Object.Environment{} = environment) do
    case length(args) do
       0 -> {:error, create_error("please provide arguments for builtin")}
       _ -> case builtin.fn.(args) do
         {:ok, val} -> {:ok, val, environment}
         {:error, error} -> {:error, error}
       end
    end
  end

  defp extend_function_env(%Object.Function{} = function, args) do
    if length(function.parameters) != length(args) do
      {:error, create_error("wrong number of arguments passed to the function #{function.name}")}
    else
      internal_store = 
        function.parameters 
        |> Enum.with_index(0) 
        |> Enum.map(fn {param, index} -> {param.value, Enum.at(args, index)} end) 
        |> Map.new()
        |> maybe_add_self(function)
      {:ok, %Object.Environment{store: internal_store, outer: function.env}}
    end

  end

  # Helpers for allowing recursion by adding the function itself to its own environment
  defp maybe_add_self(store, %Object.Function{name: nil}), do: store
  defp maybe_add_self(store, %Object.Function{name: name} = fun), do: Map.put(store, name, fun)

  defp eval_expressions(_, acc \\ [], _)
  defp eval_expressions([expression | tail], acc, %Object.Environment{} = environment) do
    case eval(expression, environment) do
      {:ok, value, env} -> eval_expressions(tail, [value | acc], env)
      {:error, error} -> {:error, error}
    end
  end
  defp eval_expressions([expression], acc, %Object.Environment{} = environment) do
    case eval(expression, environment) do
      {:ok, value, env} -> {:ok, Enum.reverse([value | acc]), env}
    end
  end
  defp eval_expressions([], acc, environment), do: {:ok, Enum.reverse(acc), environment}

  defp is_truthy?(value) do
    case value do
      %Object.Null{} -> false
      %Object.Boolean{value: true} -> true
      %Object.Boolean{value: false} -> false
      _ -> true
    end
  end

  defp eval_infix_expression("+", %Object.Integer{} = left, %Object.Integer{} = right, %Object.Environment{} = environment) do
    {:ok, %Object.Integer{value: left.value + right.value}, environment}
  end

  defp eval_infix_expression("-", %Object.Integer{} = left, %Object.Integer{} = right, %Object.Environment{} = environment) do
    {:ok, %Object.Integer{value: left.value - right.value}, environment}
  end

  defp eval_infix_expression("*", %Object.Integer{} = left, %Object.Integer{} = right, %Object.Environment{} = environment) do
    {:ok, %Object.Integer{value: left.value * right.value}, environment}
  end

  defp eval_infix_expression("/", %Object.Integer{} = left, %Object.Integer{} = right, %Object.Environment{} = environment) do
    {:ok, %Object.Integer{value: trunc(left.value / right.value)}, environment}
  end

  defp eval_infix_expression(">", %Object.Integer{} = left, %Object.Integer{} = right, %Object.Environment{} = environment) do
    {:ok, %Object.Boolean{value: left.value > right.value}, environment}
  end

  defp eval_infix_expression("<", %Object.Integer{} = left, %Object.Integer{} = right, %Object.Environment{} = environment) do
    {:ok, %Object.Boolean{value: left.value < right.value}, environment}
  end

  defp eval_infix_expression("==", %Object.Integer{} = left, %Object.Integer{} = right, %Object.Environment{} = environment) do
    {:ok, %Object.Boolean{value: left.value == right.value}, environment}
  end

  defp eval_infix_expression("!=", %Object.Integer{} = left, %Object.Integer{} = right, %Object.Environment{} = environment) do
    {:ok, %Object.Boolean{value: left.value != right.value}, environment}
  end

  defp eval_infix_expression("==", %Object.Boolean{} = left, %Object.Boolean{} = right, %Object.Environment{} = environment) do
    {:ok, %Object.Boolean{value: left.value == right.value}, environment}
  end

  defp eval_infix_expression("!=", %Object.Boolean{} = left, %Object.Boolean{} = right, %Object.Environment{} = environment) do
    {:ok, %Object.Boolean{value: left.value != right.value}, environment}
  end

  defp eval_infix_expression("+", %Object.String{} = left, %Object.String{} = right, %Object.Environment{} = environment) do
    {:ok, %Object.String{value: left.value <> right.value}, environment}
  end

  defp eval_infix_expression("!=", %Object.String{} = left, %Object.String{} = right, %Object.Environment{} = environment) do
    {:ok, %Object.Boolean{value: left.value != right.value}, environment}
  end

  defp eval_infix_expression("==", %Object.String{} = left, %Object.String{} = right, %Object.Environment{} = environment) do
    {:ok, %Object.Boolean{value: left.value == right.value}, environment}
  end


  defp eval_infix_expression(operator, left, right, %Object.Environment{} = _) do
    if Object.Object.type(left) != Object.Object.type(right) do
      {:error, create_error("type mismatch: #{Object.Object.type(left)} #{operator} #{Object.Object.type(right)}")}
    else
      {:error, create_error("unknown operator: #{Object.Object.type(left)} #{operator} #{Object.Object.type(right)}")}
    end
  end

  defp eval_prefix_expression("!", right, %Object.Environment{} = environment) do
    case right do
      %Object.Boolean{value: true} -> {:ok, %Object.Boolean{value: false}, environment}
      %Object.Boolean{value: false} -> {:ok, %Object.Boolean{value: true}, environment}
      %Object.Null{} -> {:ok, %Object.Boolean{value: true}, environment}
      _ -> {:ok, %Object.Boolean{value: false}, environment}
    end
  end

  defp eval_prefix_expression("-", %Object.Integer{value: val}, %Object.Environment{} = environment) do
    {:ok, %Object.Integer{value: -val}, environment}
  end

  defp eval_prefix_expression(operator, right, %Object.Environment{} = _) do
    {:error, create_error("unknown operator: #{operator}#{Object.Object.type(right)}")}
  end

  defp eval_program([statement], %Object.Environment{} = environment) do
    case eval(statement, environment) do
      {:ok, %Object.Return{value: value}, env} -> {:ok, value, env}
      {:ok, value, env} -> {:ok, value, env}
      {:error, error} -> {:error, error}
    end
  end

  defp eval_program([], %Object.Environment{} = environment) do
      {:ok, nil, environment}
  end

  defp eval_program([statement | tail], %Object.Environment{} = environment) do
    case eval(statement, environment) do
      {:ok, %Object.Return{value: value}, env} -> {:ok, value, env}
      {:error, error} -> {:error, error}
      {:ok, _, env} -> eval_program(tail, env)
    end
  end

  defp eval_block_statements([statement], %Object.Environment{} = environment) do
    eval(statement, environment)
  end
  
  defp eval_block_statements([statement | tail], %Object.Environment{} = environment) do
    case eval(statement, environment) do
      {:ok, %Object.Return{} = value, env} -> {:ok, value, env}
      {:error, error} -> {:error, error}
      {:ok, _, env} -> eval_block_statements(tail, env)
    end
  end

  defp eval_block_statements([], %Object.Environment{} = environment) do
    {:ok, %Object.Null{}, environment}
  end

  defp create_error(message) do
    %Object.Error{message: "ERROR: #{message}"}
  end
end
