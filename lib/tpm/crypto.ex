defmodule TPM.Crypto do
  @moduledoc """
  Interface with OTP crypto and X509.
  """

  @tpm2tss_so_path Application.compile_env(
    :tpm,
    :tpm2tss_so_path,
    "/usr/lib/engines-3/tpm2tss.so"
  )

  # Dialyzer isn't picking up these types from :crypto and X509 for some reason.
  # This is a workaround.

  @typedoc """
  [:crypto.engine_key_ref](https://www.erlang.org/docs/22/man/crypto#type-engine_key_ref)
  """
  @type engine_key_ref :: term

  @typedoc """
  [:crypto.rsa_public_key](https://www.erlang.org/docs/22/man/crypto#type-rsa_public)
  """
  @type rsa_public_key :: term

  @typedoc """
  [X509.CSR.t](https://hexdocs.pm/x509/X509.CSR.html#t:t/0)
  """
  @type x509_csr :: term

  @doc """
  Returns an OTP crypto engine for tpm2tss.
  """
  @spec engine() :: {:ok, engine :: reference} | {:error, reason :: term}
  def engine do
    :crypto.ensure_engine_loaded("tpm2tss", @tpm2tss_so_path)
  end

  @doc """
  Returns an OTP crypto [engine_key_ref](https://www.erlang.org/docs/22/man/crypto#type-engine_key_ref)
  (privkey).

  ## Args
  - `path` - File path of the TPM private key in PEM format.
  """
  @spec privkey(path :: String.t) ::
      {:ok, privkey :: engine_key_ref}
    | {:error, reason :: term}
  def privkey(path) do
    with {:ok, engine} <- engine() do
      {:ok, %{algorithm: :rsa, engine: engine, key_id: path}}
    end
  end

  @doc """
  Returns an OTP [rsa_public](https://www.erlang.org/docs/22/man/crypto#type-rsa_public)
  public key based on an OTP [engine_key_ref](https://www.erlang.org/docs/22/man/crypto#type-engine_key_ref)
  private key.

  ## Args
  - `privkey` - OTP `engine_key_ref` private key reference.
  """
  @spec pubkey(privkey :: engine_key_ref) :: rsa_public_key
  def pubkey(privkey) do
    public_key = X509.PublicKey.derive(privkey)
    {:RSAPublicKey, List.last(public_key), List.first(public_key)}
  end

  @doc """
  Create a certificate signing request for a device.

  ## Args
  - `privkey`       - OTP `engine_key_ref` private key reference.
  - `organization`  - Organization (company) name to list in the certificate.
  - `serial_number` - Device serial number or unique identifier.
  """
  @spec csr(
    privkey :: engine_key_ref,
    serial_number :: String.t,
    organization :: String.t
  ) :: x509_csr
  def csr(privkey, serial_number, organization) do
    # The module is prefixed here so the mock works
    public_key = __MODULE__.pubkey(privkey)
    X509.CSR.new(privkey, "/CN=#{serial_number}/O=#{organization}", public_key: public_key)
  end
end
