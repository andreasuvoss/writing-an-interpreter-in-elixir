defprotocol Parser.Expression do
  def token_literal(expression)
  def string(expression)
  def expression_node(node)
end
