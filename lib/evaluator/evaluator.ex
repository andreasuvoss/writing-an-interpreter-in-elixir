defmodule Evaluator.Evaluator do
  # alias Parser.ReturnStatement
  # alias Evaluator.Boolean
  # alias Parser.Boolean
  alias Evaluator.Null
  alias Evaluator.Function
  alias Evaluator.Environment
  alias Parser.ExpressionStatement
  # alias Parser.IfExpression
  alias Parser.BlockStatement
  alias Parser.IntegerLiteral
  alias Evaluator.Integer
  alias Parser.Program

  def eval(%Program{} = program, %Environment{} = environment) do
    case eval_program(program.statements, environment) do
      {:ok, result, env} -> {:ok, result, env}
      {:error, error} -> {:error, error}
    end
  end

  def eval(%ExpressionStatement{} = expression_statement, %Environment{} = environment) do
    eval(expression_statement.expression, environment)
  end

  def eval(%BlockStatement{statements: statements}, %Environment{} = environment) do
    eval_block_statements(statements, environment)
  end

  def eval(%Parser.ReturnStatement{return_value: return_value}, %Environment{} = environment) do
    case eval(return_value, environment) do
       {:ok, value, env} -> {:ok, %Evaluator.Return{value: value}, env}
       {:error, error} -> {:error, error}
    end
  end

  def eval(%Parser.IfExpression{} = expr, %Environment{} = environment) do
    case eval(expr.condition, environment) do
      {:ok, condition, env} -> case {is_truthy?(condition), expr.alternative} do
        {true, _} -> eval(expr.consequence, env)
        {false, nil} -> {:ok, %Evaluator.Null{}, env}
        {false, alternative} -> eval(alternative, env)
      end
      {:error, error} -> {:error, error}
    end
  end

  def eval(%IntegerLiteral{} = integer, %Environment{} = environment) do
    {:ok, %Integer{value: integer.value}, environment}
  end

  def eval(%Parser.Boolean{} = bool, %Environment{} = environment) do
    {:ok, %Evaluator.Boolean{value: bool.value}, environment}
  end

  def eval(%Parser.PrefixExpression{} = expr, %Environment{} = environment) do
    case eval(expr.right, environment) do
      {:ok, right, env} -> eval_prefix_expression(expr.operator, right, env)
      {:error, error} -> {:error, error}
    end
  end

  def eval(%Parser.InfixExpression{} = expr, %Environment{} = environment) do
    case eval(expr.left, environment) do
      {:ok, left, env} ->
        case eval(expr.right, env) do
          {:ok, right, env} -> eval_infix_expression(expr.operator, left, right, env)
          {:error, error} -> {:error, error}
        end
      {:error, error} -> {:error, error}
    end
  end

  def eval(%Parser.Identifier{} = identifier, %Environment{} = environment) do
    case Evaluator.Environment.get(environment, identifier.value) do
        {:ok, val} -> {:ok, val, environment}
        {:error, error} -> {:error, create_error(error)}
    end
  end

  def eval(%Parser.LetStatement{value: %Parser.FunctionLiteral{} = literal} = stmt, %Environment{} = environment) do
    name = stmt.name.token.literal
    case eval(literal, environment) do
      {:ok, fun, _}  -> {:ok, %{fun | name: name}, Environment.set(environment, name, %{fun | name: name})}
    end
  end

  def eval(%Parser.LetStatement{} = stmt, %Environment{} = environment) do
    case eval(stmt.value, environment) do
      {:ok, value, %Environment{} = env} -> {:ok, value, Environment.set(env, stmt.name.value, value)}
      {:error, error} -> {:error, error}
    end
  end


  def eval(%Parser.FunctionLiteral{} = function, %Environment{} = environment) do
    # IO.inspect(environment)
    {:ok, %Function{parameters: function.parameters, body: function.body, env: environment}, environment}
  end

  def eval(%Parser.CallExpression{} = call_expression, %Environment{} = environment) do
    case eval(call_expression.function, environment) do
      {:ok, function, env} -> case eval_expressions(call_expression.arguments, env) do
        {:ok, args, env} -> apply_function(function, args, env)
      end
    end
  end

  defp apply_function(%Function{} = function, args, %Environment{} = environment) do
    # extended_env = extend_function_env(function, args)
    case extend_function_env(function, args) do
      {:ok, extended_env} -> 
        case eval(function.body, extended_env) do
          {:ok, %Evaluator.Return{} = ret, _} -> {:ok, ret.value, environment}
          {:ok, val, _} -> {:ok, val, environment}
        end
      {:error, error} -> {:error, error}
    end

    
  end

  def extend_function_env(%Function{} = function, args) do
    if length(function.parameters) != length(args) do
      {:error, create_error("wrong number of arguments passed to the function #{function.name}")}
    else
      internal_store = 
        function.parameters 
        |> Enum.with_index(0) 
        |> Enum.map(fn {param, index} -> {param.value, Enum.at(args, index)} end) 
        |> Map.new()
        |> maybe_add_self(function)
      {:ok, %Environment{store: internal_store, outer: function.env}}
    end

  end

  # Helpers for allowing recursion by adding the function itself to its own environment
  defp maybe_add_self(store, %Function{name: nil}), do: store
  defp maybe_add_self(store, %Function{name: name} = fun), do: Map.put(store, name, fun)

  # let counter = fn(x) { if (x > 100 ) {return true; } else { let foobar = 9999; counter(x+1) } };

  # WORKS: let a = fn(x) { if(x > 10) { true } else { a(x + 1) } }
  # DOESNT: let a = fn(x) { if(x > 10) { true } else { let y = 1; a(x + 1) }}

  # defp unwrap_return_value() do
  #   
  # end

  defp eval_expressions(_, acc \\ [], _)
  defp eval_expressions([expression | tail], acc, %Environment{} = environment) do
    case eval(expression, environment) do
      {:ok, value, env} -> eval_expressions(tail, [value | acc], env)
      {:error, error} -> {:error, error}
    end
  end
  defp eval_expressions([expression], acc, %Environment{} = environment) do
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

  defp eval_infix_expression("+", %Evaluator.Integer{} = left, %Evaluator.Integer{} = right, %Environment{} = environment) do
    {:ok, %Evaluator.Integer{value: left.value + right.value}, environment}
  end

  defp eval_infix_expression("-", %Evaluator.Integer{} = left, %Evaluator.Integer{} = right, %Environment{} = environment) do
    {:ok, %Evaluator.Integer{value: left.value - right.value}, environment}
  end

  defp eval_infix_expression("*", %Evaluator.Integer{} = left, %Evaluator.Integer{} = right, %Environment{} = environment) do
    {:ok, %Evaluator.Integer{value: left.value * right.value}, environment}
  end

  defp eval_infix_expression("/", %Evaluator.Integer{} = left, %Evaluator.Integer{} = right, %Environment{} = environment) do
    {:ok, %Evaluator.Integer{value: left.value / right.value}, environment}
  end

  defp eval_infix_expression(">", %Evaluator.Integer{} = left, %Evaluator.Integer{} = right, %Environment{} = environment) do
    {:ok, %Evaluator.Boolean{value: left.value > right.value}, environment}
  end

  defp eval_infix_expression("<", %Evaluator.Integer{} = left, %Evaluator.Integer{} = right, %Environment{} = environment) do
    {:ok, %Evaluator.Boolean{value: left.value < right.value}, environment}
  end

  defp eval_infix_expression("==", %Evaluator.Integer{} = left, %Evaluator.Integer{} = right, %Environment{} = environment) do
    {:ok, %Evaluator.Boolean{value: left.value == right.value}, environment}
  end

  defp eval_infix_expression("!=", %Evaluator.Integer{} = left, %Evaluator.Integer{} = right, %Environment{} = environment) do
    {:ok, %Evaluator.Boolean{value: left.value != right.value}, environment}
  end

  defp eval_infix_expression("==", %Evaluator.Boolean{} = left, %Evaluator.Boolean{} = right, %Environment{} = environment) do
    {:ok, %Evaluator.Boolean{value: left.value == right.value}, environment}
  end

  defp eval_infix_expression("!=", %Evaluator.Boolean{} = left, %Evaluator.Boolean{} = right, %Environment{} = environment) do
    {:ok, %Evaluator.Boolean{value: left.value != right.value}, environment}
  end

  defp eval_infix_expression(operator, left, right, %Environment{} = _) do
    if Evaluator.Object.type(left) != Evaluator.Object.type(right) do
      {:error, create_error("type mismatch: #{Evaluator.Object.type(left)} #{operator} #{Evaluator.Object.type(right)}")}
    else
      {:error, create_error("unknown operator: #{Evaluator.Object.type(left)} #{operator} #{Evaluator.Object.type(right)}")}
    end
  end

  defp eval_prefix_expression("!", right, %Environment{} = environment) do
    case right do
      %Evaluator.Boolean{value: true} -> {:ok, %Evaluator.Boolean{value: false}, environment}
      %Evaluator.Boolean{value: false} -> {:ok, %Evaluator.Boolean{value: true}, environment}
      %Evaluator.Null{} -> {:ok, %Evaluator.Boolean{value: true}, environment}
      _ -> {:ok, %Evaluator.Boolean{value: false}, environment}
    end
  end

  defp eval_prefix_expression("-", %Evaluator.Integer{value: val}, %Environment{} = environment) do
    {:ok, %Evaluator.Integer{value: -val}, environment}
  end

  defp eval_prefix_expression(operator, right, %Environment{} = _) do
    {:error, create_error("unknown operator: #{operator}#{Evaluator.Object.type(right)}")}
  end

  defp eval_program([statement], %Environment{} = environment) do
    case eval(statement, environment) do
      {:ok, %Evaluator.Return{value: value}, env} -> {:ok, value, env}
      {:ok, value, env} -> {:ok, value, env}
      {:error, error} -> {:error, error}
    end
  end

  defp eval_program([statement | tail], %Environment{} = environment) do
    case eval(statement, environment) do
      {:ok, %Evaluator.Return{value: value}, env} -> {:ok, value, env}
      {:error, error} -> {:error, error}
      {:ok, _, env} -> eval_program(tail, env)
    end
  end

  def eval_block_statements([statement], %Environment{} = environment) do
    # IO.inspect(statement)
    # IO.inspect(environment)
    eval(statement, environment)
  end
  
  def eval_block_statements([statement | tail], %Environment{} = environment) do
    # IO.inspect(statement)
    # IO.inspect(environment)
    case eval(statement, environment) do
      {:ok, %Evaluator.Return{} = value, env} -> {:ok, value, env}
      {:error, error} -> {:error, error}
      {:ok, _, env} -> eval_block_statements(tail, env)
    end
  end

  
  def eval_block_statements([], %Environment{} = environment) do
    {:ok, %Null{}, environment}
  end


  # let q = fn(x){ let z = fn(x){ if(x > 10) { true;} else {z(x+1)}} z(x)}

  defp create_error(message) do
    %Evaluator.Error{message: message}
  end
end
