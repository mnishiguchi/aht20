# Always warning as errors
if Version.match?(System.version(), "~> 1.10") do
  Code.put_compiler_option(:warnings_as_errors, true)
end

# Define dynamic mocks
Mox.defmock(AHT20.MockTransport, for: AHT20.Transport)

# Override the config settings
Application.put_env(:aht20, :transport_module, AHT20.MockTransport)

ExUnit.start()
