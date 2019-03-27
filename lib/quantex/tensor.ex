#
#   Copyright 2019 OpenQL Project developers.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#

defmodule QuantEx.Tensor do
  @moduledoc """
  Tensor library namespace.
  use `use QuantEx.Tensor` to alias `Tensor`.
  """
  @doc false
  defmacro __using__(_opts) do
    quote do
      alias Tensor.Tensor
    end
  end
end

defmodule Tensor.TBase do
  @base_fields [to_list: [], shape: []]
  defmacro __using__(fields) do
    fields = @base_fields ++ fields
    quote do
      defstruct unquote(fields)
    end
  end
end

defmodule Tensor.Tensor do
  alias Tensor.{Tensor, TBase}
  use TBase

  @type tensor(list, shape) :: %Tensor{to_list: list, shape: shape}
  @opaque tensor :: %Tensor{to_list: list, shape: list(non_neg_integer)}

  defimpl Inspect, for: Tensor do
    def inspect(tensor, _opts) do
      "Tensor[#{tensor.shape |> Enum.join("x")}] (#{inspect tensor.to_list})"
    end
  end

  @spec new([], [non_neg_integer]) :: tensor
  def new(nested_list_of_values, shape \\ []) do
    lists = nested_list_of_values
            |> List.flatten
    %Tensor{to_list: lists, shape: shape}
  end

  @spec tensor?(tensor) :: boolean
  def tensor?(%Tensor{}), do: true

  @spec is_tensor(term) :: boolean
  def is_tensor(t), do: tensor?(t)

  @spec vector?(tensor) :: boolean
  def vector?(%Tensor{shape: [_]}), do: true
  def vector?(%Tensor{}), do: false

  @spec is_vector(term) :: boolean
  def is_vector(t), do: vector?(t)

  @spec matrix?(tensor) :: boolean
  def matrix?(%Tensor{shape: [_,_]}), do: true
  def matrix?(%Tensor{}), do: false

  @spec is_matrix(term) :: boolean
  def is_matrix(t), do: matrix?(t)

  @spec swap(list, non_neg_integer, non_neg_integer) :: list
  defp swap(list, a, b) when a < b do
    {h, rest} = Enum.split(list, a)
    {center, t} = Enum.split(rest, b - a)
    h ++ [hd(t)] ++ tl(center) ++ [hd(center)] ++ tl(t)
  end
  defp swap(list, a, b) when b < a, do: swap(list, b, a)
  defp swap(list, a, a), do: list

end
