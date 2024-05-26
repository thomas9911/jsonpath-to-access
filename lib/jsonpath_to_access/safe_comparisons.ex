defmodule JsonpathToAccess.SafeComparisions do
  defguard is_same_type(a, b)
           when (is_atom(a) and is_atom(b)) or (is_list(a) and is_list(b)) or
                  (is_map(a) and is_map(b)) or (is_tuple(a) and is_tuple(b)) or
                  (is_binary(a) and is_binary(b)) or (is_integer(a) and is_integer(b)) or
                  (is_float(a) and is_float(b)) or
                  (is_boolean(a) and is_boolean(b)) or
                  (is_nil(a) and is_nil(b))

  defdelegate a == b, to: Kernel
  defdelegate a != b, to: Kernel

  def a > b when is_same_type(a, b), do: Kernel.>(a, b)
  def _ > _, do: false

  def a >= b when is_same_type(a, b), do: Kernel.>=(a, b)
  def _ >= _, do: false

  def a < b when is_same_type(a, b), do: Kernel.<(a, b)
  def _ < _, do: false

  def a <= b when is_same_type(a, b), do: Kernel.<=(a, b)
  def _ <= _, do: false
end
