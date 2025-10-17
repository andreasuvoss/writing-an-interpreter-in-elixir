defprotocol Parser.Statement do
  def token_literal(statement)
  def statement_node(node)
end
