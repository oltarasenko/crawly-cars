defmodule CarsShopTest do
  use ExUnit.Case
  doctest CarsShop

  test "greets the world" do
    assert CarsShop.hello() == :world
  end
end
