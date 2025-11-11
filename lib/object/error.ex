defmodule Object.Error do
  defstruct  message: ""

  defimpl Object.Object, for: Object.Error do
    def type(_) do
      "ERROR"
    end
  end
end
