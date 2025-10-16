defprotocol Parser.Statement do
  def token_literal(statement)
  def string(statement)
  def statement_node(node)
end
