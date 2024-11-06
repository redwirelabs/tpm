defmodule TPM do
  @moduledoc """
  Elixir wrapper for [tpm2-tools](https://github.com/tpm2-software/tpm2-tools).
  """

  @type tpm2_error ::
      {:error, :invalid_options, message :: String.t}
    | {:error, :not_authorized, message :: String.t}
    | {:error, :tcti, message :: String.t}
    | {:error, :unsupported_scheme, message :: String.t}
    | {:error, return_code :: non_neg_integer, message :: String.t}

  @tpm_device Application.compile_env(:tpm, :device_path, "/dev/tpmrm0")

  @doc """
  Clear the TPM.

  ## Opts
  - `confirm` - Must be set `true` to clear the TPM. This prevents accidental \
                auto-completion in IEx.
  """
  @spec clear([confirm: boolean]) :: :ok | tpm2_error | :no_return
  def clear(opts)

  def clear(confirm: true) do
    case cmd("tpm2_clear", ["-T", "device:#{@tpm_device}"]) do
      {:ok, _} -> :ok
      error    -> error
    end
  end

  def clear(_) do
    raise "Must set `confirm: true` to clear the TPM"
  end

  @doc """
  Get TPM capabilities.
  """
  @spec getcap(capability :: :handles_nv_index) :: {:ok, [String.t]} | tpm2_error
  def getcap(_capability = :handles_nv_index) do
    case cmd("tpm2_getcap", ["-T", "device:#{@tpm_device}", "handles-nv-index"]) do
      {:ok, stdout} ->
        addresses =
          stdout
          |> String.replace("- ", "")
          |> String.split("\n", trim: true)

        {:ok, addresses}

      error ->
        error
    end
  end

  @doc """
  Define a TPM Non-Volatile (NV) index.

  ## Opts
  - `address` - NV index or offset number.
  - `size`    - Specifies  the  size  of data area in bytes. Defaults to \
                MAX_NV_INDEX_SIZE which is typically 2048.
  """
  @spec nvdefine([address: String.t, size: pos_integer]) ::
    {:ok, String.t} | tpm2_error
  def nvdefine(opts \\ []) do
    args =
      Enum.reduce(opts, [], fn
        {:size, size}, acc ->
          acc ++ ["-s", to_string(size)]

        {:address, address}, acc ->
          acc ++ [address]

        {_, _}, acc ->
          acc
      end)

    case cmd("tpm2_nvdefine", ["-T", "device:#{@tpm_device}"] ++ args) do
      {:ok, stdout} ->
        # stdout format:
        # nv-index: 0x1000001
        address =
          stdout
          |> String.split
          |> List.last

        {:ok, address}

      error ->
        error
    end
  end

  @doc """
  Read the data stored in a Non-Volatile (NV) index.

  ## Args
  - `address` - NV memory address.

  ## Opts
  - `output` - File path to write the NV memory's contents to. Returns `:ok`.
  """
  @spec nvread(address :: String.t, [output: String.t]) ::
    :ok | {:ok, String.t} | tpm2_error
  def nvread(address, opts \\ []) do
    args =
      Enum.reduce(opts, [], fn
        {:output, path}, acc ->
          acc ++ ["-o", path]

        {_, _}, acc ->
          acc
      end)

    return_contents? = Keyword.has_key?(opts, :output) == false

    case cmd(
      "tpm2_nvread",
      ["-T", "device:#{@tpm_device}"] ++ args ++ [address],
      stderr_to_stdout: !return_contents?
    ) do
      {:ok, _stdout} when not return_contents? ->
        :ok

      result ->
        result
    end
  end

  @doc """
  Write data to a Non-Volatile (NV) index.

  ## Args
  - `address` - NV memory address.
  - `path`    - File path to read into the NV memory's contents.
  """
  @spec nvwrite(address :: String.t, path :: String.t) :: :ok | tpm2_error
  def nvwrite(address, path) do
    case cmd("tpm2_nvwrite", ["-i", path, "-T", "device:#{@tpm_device}", address]) do
      {:ok, _} -> :ok
      error    -> error
    end
  end

  defp cmd(command, args, opts \\ []) do
    opts = Keyword.put_new(opts, :stderr_to_stdout, true)

    case MuonTrap.cmd(command, args, opts) do
      {stdout,  0}    -> {:ok, stdout}
      {message, 2}    -> {:error, :invalid_options, message}
      {message, 3}    -> {:error, :not_authorized, message}
      {message, 4}    -> {:error, :tcti, message}
      {message, 5}    -> {:error, :unsupported_scheme, message}
      {message, code} -> {:error, code, message}
    end
  end
end
