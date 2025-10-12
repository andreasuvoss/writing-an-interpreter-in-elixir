defprotocol Parser.Statement do
  def token_literal(statement)
  def node(node)
end
