defprotocol Parser.Expression do
  def token_literal(expression)
  def expression_node(node)
end
