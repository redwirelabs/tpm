defmodule TPM.TSS do
  @moduledoc """
  Elixir wrapper for [tpm2tss](https://github.com/tpm2-software/tpm2-tss).
  """

  @tpm_device Application.compile_env(:tpm, :device_path, "/dev/tpmrm0")

  @doc """
  Generate TPM keys for tpm2-tss-engine.

  ## Args
  - `output_path` - File path to save the generated key.
  """
  @spec genkey(output_path :: String.t) ::
    :ok | {:error, return_code :: non_neg_integer, message :: String.t}
  def genkey(output_path) do
    case cmd("tpm2tss-genkey", ["-a", "rsa", "-t", "device:#{@tpm_device}", output_path]) do
      {:ok, _} -> :ok
      error    -> error
    end
  end

  defp cmd(command, args, opts \\ []) do
    opts = opts ++ [stderr_to_stdout: true]

    case MuonTrap.cmd(command, args, opts) do
      {stdout,  0}    -> {:ok, stdout}
      {message, code} -> {:error, code, message}
    end
  end
end
