defprotocol Evaluator.Object do
  def type(object)
  def inspect(object)
end
