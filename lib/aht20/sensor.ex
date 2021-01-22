defmodule AHT20.Sensor do
  @moduledoc """
  Abstracts the basic operations of the temperature and humidity sensor AHT20.
  For the AHT20 specifications, please refer to the [AHT20 data sheet](https://cdn.sparkfun.com/assets/d/2/b/e/d/AHT20.pdf).
  """

  require Logger
  use Bitwise, only_operators: true
  alias AHT20.I2C.Device, as: I2CDevice

  @default_i2c_bus "i2c-1"
  @default_i2c_address 0x38

  @aht20_cmd_initialize 0xBE
  @aht20_cmd_trigger_measurement 0xAC
  @aht20_cmd_soft_reset 0xBA
  @aht20_cmd_read_state 0x71

  @type i2c_bus :: AHT20.I2C.bus_name()
  @type i2c_address :: AHT20.I2C.address()

  @typedoc """
  The configuration options.
  """
  @type config :: %{
          optional(:i2c_bus) => i2c_bus,
          optional(:i2c_address) => i2c_address
        }

  defstruct [:i2c_bus, :i2c_ref, :i2c_address]

  @typedoc """
  Represents the connection to the sensor.
  """
  @type t :: %__MODULE__{
          i2c_bus: i2c_bus,
          i2c_ref: reference,
          i2c_address: i2c_address
        }

  @doc """
  Connects to the sensor.
  For more info. please refer to the data sheet (section 5.4).
  """
  @spec start(config) :: {:ok, t} | {:error, any}
  def start(config \\ %{}) do
    with i2c_bus <- config[:i2c_bus] || @default_i2c_bus,
         i2c_address <- config[:i2c_address] || @default_i2c_address,
         {:ok, i2c_ref} <- I2CDevice.open(i2c_bus),
         sensor <- __struct__(i2c_bus: i2c_bus, i2c_ref: i2c_ref, i2c_address: i2c_address),
         :ok <- Process.sleep(40),
         :ok <- reset(sensor),
         :ok <- init(sensor) do
      {:ok, sensor}
    else
      {:error, reason} -> {:error, reason}
      unexpected -> {:error, unexpected}
    end
  end

  @doc """
  Restarts the sensor system without having to turn off and turn on the power again.
  Soft reset takes no longer than 20ms.
  For more info. please refer to the data sheet (section 5.5).
  """
  @spec reset(t) :: :ok | {:error, any}
  def reset(%{i2c_ref: i2c_ref, i2c_address: i2c_address}) do
    with :ok <- I2CDevice.write(i2c_ref, i2c_address, [@aht20_cmd_soft_reset]),
         :ok <- Process.sleep(20) do
      :ok
    else
      {:error, reason} -> {:error, reason}
    end
  end

  # Initialize the sensor system.
  # For more info. please refer to the data sheet (section 5.4).
  @spec init(t) :: :ok | :no_return
  defp init(%{i2c_ref: i2c_ref, i2c_address: i2c_address}) do
    I2CDevice.write(i2c_ref, i2c_address, [@aht20_cmd_initialize, 0x08, 0x00])
  end

  @doc """
  Triggers the sensor to read temperature and humidity.
  """
  @spec read_data(t) :: {:ok, <<_::56>>} | {:error, any}
  def read_data(%{i2c_ref: i2c_ref, i2c_address: i2c_address}) do
    with :ok <- I2CDevice.write(i2c_ref, i2c_address, [@aht20_cmd_trigger_measurement, 0x33, 0x00]),
         :ok <- Process.sleep(75),
         {:ok, data} <- I2CDevice.read(i2c_ref, i2c_address, 7) do
      {:ok, data}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Obtains the sensor status byte.
  For more info. please refer to the data sheet (section 5.3).
  """
  @spec read_state(t) :: {:ok, <<_::8>>} | {:error, any}
  def read_state(%{i2c_ref: i2c_ref, i2c_address: i2c_address}) do
    I2CDevice.write_read(i2c_ref, i2c_address, [@aht20_cmd_read_state], 1)
  end
end
