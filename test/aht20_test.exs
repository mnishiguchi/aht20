defmodule AHT20Test do
  use ExUnit.Case

  # https://hexdocs.pm/mox/Mox.html
  import Mox

  # Any process can consume mocks and stubs defined in your tests.
  setup :set_mox_from_context

  # Make sure mocks are verified when the test exits
  setup :verify_on_exit!

  setup do
    Mox.stub_with(AHT20.MockI2C, AHT20.Transport.I2C.Stub)
    :ok
  end

  test "start_link" do
    assert {:ok, transport} = AHT20.start_link(bus_name: "i2c-1", bus_address: 0x38)
    assert is_pid(transport)
  end

  test "measure" do
    AHT20.MockI2C
    |> Mox.expect(:read, 1, fn _transport, _register ->
      {:ok, <<28, 113, 191, 6, 86, 169, 149>>}
    end)

    assert {:ok, pid} = AHT20.start_link()
    assert {:ok, data} = AHT20.measure(pid)

    assert %AHT20.Measurement{
             dew_point_c: 15.881025820111912,
             humidity_rh: 44.43206787109375,
             temperature_c: 29.23145294189453,
             timestamp_ms: _
           } = data
  end
end
