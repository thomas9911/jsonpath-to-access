defmodule JsonpathToAccess.SafeComparisionsTest do
  use ExUnit.Case, async: true

  alias JsonpathToAccess.SafeComparisions

  test "> same when types are the same" do
    assert 2 > 1
    refute 1 > 2
    assert SafeComparisions.>(2, 1)
    refute SafeComparisions.>(1, 2)
  end

  test "> same when types are not the same" do
    assert %{} > 1
    refute SafeComparisions.>(%{}, 1)
  end

  test ">= same when types are the same" do
    assert 2 >= 1
    assert 2 >= 2
    refute 1 >= 2
    assert SafeComparisions.>=(2, 1)
    assert SafeComparisions.>=(2, 2)
    refute SafeComparisions.>=(1, 2)
  end

  test ">= same when types are not the same" do
    assert %{} >= 1
    assert %{} >= 2
    refute 1 >= %{}
    refute SafeComparisions.>=(%{}, 1)
    refute SafeComparisions.>=(%{}, 2)
    refute SafeComparisions.>=(2, %{})
  end

  test "< same when types are the same" do
    refute 2 < 1
    assert 1 < 2
    refute SafeComparisions.<(2, 1)
    assert SafeComparisions.<(1, 2)
  end

  test "< same when types are not the same" do
    assert 1 < %{}
    refute SafeComparisions.<(1, %{})
  end

  test "<= same when types are the same" do
    assert 1 <= 2
    assert 2 <= 2
    refute 2 <= 1
    assert SafeComparisions.<=(1, 2)
    assert SafeComparisions.<=(2, 2)
    refute SafeComparisions.<=(2, 1)
  end

  test "<= same when types are not the same" do
    refute %{} <= 1
    refute %{} <= 2
    assert 1 <= %{}
    assert 2 <= %{}
    refute SafeComparisions.<=(%{}, 1)
    refute SafeComparisions.<=(%{}, 2)
    refute SafeComparisions.<=(1, %{})
    refute SafeComparisions.<=(2, %{})
  end

  test "==" do
    assert SafeComparisions.==(1, 1)
    refute SafeComparisions.==(1, 2)
  end

  test "!=" do
    refute SafeComparisions.!=(1, 1)
    assert SafeComparisions.!=(1, 2)
  end
end
