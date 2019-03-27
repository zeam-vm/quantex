#
#   Copyright 2018-2019 piacere.
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

defmodule QuantEx.Operator do
  @moduledoc """
  """
  @doc false
  defmacro __using__(_opts) do
    quote do
      alias QuantEx.Qop
    end
  end

end

defmodule QuantEx.Qop do
  @moduledoc """
  """

  require Math

  import Kernel, except: [+: 2, -: 2, *: 2,
                          if: 2, unless: 2
                          ]

  use QuantEx.Complex
  use QuantEx.Qubit
  use QuantEx.Unitary
  use QuantEx.Tensor
  use QuantEx.Circuit

  alias Complex, as: C
  alias Qubit, as: Q
  alias Unitary, as: U
  alias Tensor, as: T

  ### for guard

  defguard is_unitary(value) when value === %Unitary{}

  @doc guard: true
  @spec unitary?(term) :: boolean
  def unitary?(%Unitary{}), do: true
  def unitary?(_), do: false

  @doc """

  ## Examples

    iex> import Kernel, except: [+: 2]
    iex> import QuantEx.Qop
    iex> 1 + 2
    3

  """
  @spec C.real_complex + C.real_complex :: C.real_complex
  def left + right, do: C.add(left, right)

  @doc """

  ## Examples

    iex> import Kernel, except: [-: 2]
    iex> import QuantEx.Qop
    iex> 2 - 1
    1

  """
  @spec C.real_complex - C.real_complex :: C.real_complex
  def left - right, do: C.sub(left, right)

  @doc """

  ## Examples

    iex> import Kernel, except: [*: 2]
    iex> import QuantEx.Qop
    iex> 2 * 3
    6

  """
  @spec C.real_complex * C.real_complex :: C.real_complex
  def left * right, do: C.mul(left, right)

  @doc """

  ## Examples

    iex> import Kernel, except: [/: 2]
    iex> import QuantEx.Qop
    iex> 6 / 2
    3.0

  """
  @spec C.real_complex / C.real_complex :: C.real_complex
  def left / right, do: C.div(left, right)

  defdelegate abs(real_complex), to: C
  defdelegate div(real_complex, real_complex), to: C

  @doc """

  ## Examples

    iex> import Kernel, except: [if: 2]
    iex> import QuantEx.Qop
    iex> if(true, do: true)
    true
    iex> if(true, do: true, else: false)
    true
    iex> if(false, do: true, else: false)
    false

  """
  defmacro if(condition, clauses) do
    build_if(condition, clauses)
  end

  defp optimize_boolean({:case, meta, args}) do
    {:case, [{:optimize_boolean, true} | meta], args}
  end

  defp build_if(condition, do: do_clause) do
    build_if(condition, do: do_clause, else: nil)
  end

  defp build_if(condition, do: do_clause, else: else_clause) do
    optimize_boolean(
      quote do
        case unquote(condition) do
          x when :"Elixir.Kernel".in(x, [false, nil]) -> unquote(else_clause)
          _ -> unquote(do_clause)
        end
      end
    )
  end

  defp build_if(_condition, _arguments) do
    raise ArgumentError,
          "invalid or duplicate keys for if, only \"do\" and an optional \"else\" are permitted"
  end

  @doc """

  ## Examples

    iex> import Kernel, except: [if: 2, unless: 2]
    iex> import QuantEx.Qop
    iex> unless(true, do: true)
    nil
    iex> unless(true, do: true, else: false)
    false
    iex> unless(false, do: true, else: false)
    true

  """
  defmacro unless(condition, clauses) do
    build_unless(condition, clauses)
  end

  defp build_unless(condition, do: do_clause) do
    build_unless(condition, do: do_clause, else: nil)
  end

  defp build_unless(condition, do: do_clause, else: else_clause) do
    quote do
      if(unquote(condition), do: unquote(else_clause), else: unquote(do_clause))
    end
  end

  defp build_unless(_condition, _arguments) do
    raise ArgumentError,
          "invalid or duplicate keys for unless, only \"do\" and an optional \"else\" are permitted"
  end

  @doc """
  create pure state qubit
  """
  @spec pure(list) :: Q.qubit
  @spec pure(integer, T.tensor) :: Q.qubit
  defdelegate pure(list), to: Q
  defdelegate pure(num, state), to: Q

  def qubit(list), do: pure(list)
  def qubit(num, state), do: pure(num, state)

  @doc """
  U1 gate. - 1 qubit operator
 
  ## Examples

    iex> QuantEx.Qop.x.n
    1
    iex> QuantEx.Qop.x.shape
    [2, 2]

  """
  @spec u1(integer, U.unitary, Qit.circuit) :: Qit.circuit
  @spec u1(integer, U.unitary, U.unitary) :: Qit.circuit
  @spec u1(integer, U.unitary, Q.qubit) :: Qit.circuit
  @spec u1(integer, U.unitary) :: U.unitary
  @spec u1(U.unitary) :: U.unitary
  def u1(t, u, qubit), do: nil
  def u1(t, u), do: U.new(t, u.to_list)
  def u1(t) when is_integer(t), do: &u1(t, &1)   # for curry
  def u1(u) when is_unitary(u), do: u

  @doc """
  X gate.
 
  ## Examples

    iex> QuantEx.Qop.x.n
    1
    iex> QuantEx.Qop.x.shape
    [2, 2]

  """
  @spec x(integer, Qit.circuit) :: Qit.circuit
  @spec x(integer, U.unitary) :: Qit.circuit
  @spec x(integer, Q.qubit) :: Qit.circuit
  @spec x(integer) :: U.unitary
  @spec x() :: U.unitary
  def x(n, qubit), do: nil
  def x(n), do: &x(n, &1)
  def x, do: U.new([C.new(0), C.new(1), C.new(1), C.new(0)])

  @doc """
  Y gate.
 
  ## Examples

    iex> QuantEx.Qop.y.n
    1
    iex> QuantEx.Qop.y.shape
    [2, 2]

  """
  @spec y(integer, Q.qubit) :: Qit.circuit
  @spec y(integer) :: U.unitary
  @spec y() :: U.unitary
  def y(n, qubit), do: nil
  def y(n), do: &y(n, &1)
  def y, do: U.new([C.new(0), C.new(0,-1), C.new(0,1), C.new(0)])

  @doc """
  Z gate.
 
  ## Examples

    iex> QuantEx.Qop.z.n
    1
    iex> QuantEx.Qop.z.shape
    [2, 2]

  """
  @spec z(integer, Q.qubit) :: Qit.circuit
  @spec z(integer) :: U.unitary
  @spec z() :: U.unitary
  def z(n, qubit), do: nil
  def z(n), do: &z(n, &1)
  def z, do: U.new([C.new(1), C.new(0), C.new(0), C.new(-1)])

  defp r1_2, do:  Complex.div(1, :math.sqrt(2))

  @doc """
  H(Hadamard) gate.
 
  ## Examples

    iex> QuantEx.Qop.h.n
    1
    iex> QuantEx.Qop.h.shape
    [2, 2]

  """
  @spec h(integer, Q.qubit) :: Qit.circuit
  @spec h(integer) :: U.unitary
  @spec h() :: U.unitary
  def h(n, qubit), do: nil
  def h(n), do: &h(n, &1)
  def h, do: U.new([C.new(r1_2()), C.new(r1_2()), C.new(r1_2()), C.new(-1*r1_2())])

  @doc """
  CX(CNOT) gate.
 
  ## Examples

    iex> QuantEx.Qop.cx.n
    2
    iex> QuantEx.Qop.cx.shape
    [4, 4]
    iex> QuantEx.Qop.cnot.n
    2
    iex> QuantEx.Qop.cnot.shape
    [4, 4]

  """
  @spec cx(integer, Q.qubit) :: Qit.circuit
  @spec cx(integer) :: U.unitary
  @spec cx() :: U.unitary
  def cx(n, qubit), do: nil
  def cx(n), do: &h(n, &1)
  def cx, do: U.new([C.new(1), C.new(0), C.new(0), C.new(0),
                     C.new(0), C.new(1), C.new(0), C.new(0),
                     C.new(0), C.new(0), C.new(0), C.new(1),
                     C.new(0), C.new(0), C.new(1), C.new(0)
                    ])

  @spec cnot(integer, Q.qubit) :: Qit.circuit
  @spec cnot(integer) :: U.unitary
  @spec cnot() :: U.unitary
  def cnot(n, qubit), do: cx(n, qubit)
  def cnot(n), do: cx(n)
  def cnot, do: cx()

# @doc """
# Calculate tensor product.<br>
# TODO: Later, transfer to Numexy github
#
# ## Examples
#   iex> Q.tensordot( Q.q0(), Q.q0(), 0 )
#   Numexy.new( [ 1, 0, 0, 0 ] )
#   iex> Q.tensordot( Q.q0(), Q.q1(), 0 )
#   Numexy.new( [ 0, 1, 0, 0 ] )
#   iex> Q.tensordot( Q.q1(), Q.q0(), 0 )
#   Numexy.new( [ 0, 0, 1, 0 ] )
#   iex> Q.tensordot( Q.q1(), Q.q1(), 0 )
#   Numexy.new( [ 0, 0, 0, 1 ] )
# """
# def tensordot( %Array{ array: xm, shape: _xm_shape }, %Array{ array: ym, shape: _ym_shape }, _axes ) do
#   xv = List.flatten( xm )
#   yv = List.flatten( ym )
#   xv
#   |> Enum.map( fn x -> yv |> Enum.map( fn y -> x * y end ) end )
#   |> List.flatten
#   |> Numexy.new
# end
end