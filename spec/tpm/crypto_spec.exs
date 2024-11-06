defmodule TPM.Crypto.Spec do
  use ESpec

  alias TPM.Crypto

  let :engine,           do: make_ref()
  let :tpm2tss_so_path,  do: Application.fetch_env!(:tpm, :tpm2tss_so_path)
  let :private_key_path, do: "/tmp/tpm_ex/key"

  context "engine:" do

    it "returns an OTP crypto engine for tpm2tss" do
      allow :crypto |> to(accept :ensure_engine_loaded, fn name, path ->
        name |> should(eq "tpm2tss")
        path |> should(eq tpm2tss_so_path())

        {:ok, engine()}
      end)

      Crypto.engine |> should(eq {:ok, engine()})

      expect :crypto |> to(accepted :ensure_engine_loaded, :any, count: 1)
    end

    it "returns an error if the engine doesn't exist" do
      allow :crypto |> to(accept :ensure_engine_loaded, fn _name, _path ->
        {:error, :ctrl_cmd_failed}
      end)

      Crypto.engine |> should(eq {:error, :ctrl_cmd_failed})

      expect :crypto |> to(accepted :ensure_engine_loaded, :any, count: 1)
    end
  end

  context "privkey:" do
    it "returns an OTP engine key ref" do
      allow :crypto |> to(accept :ensure_engine_loaded, fn _name, _path ->
        {:ok, engine()}
      end)

      Crypto.privkey(private_key_path()) |> should(eq \
        {:ok, %{algorithm: :rsa, engine: engine(), key_id: private_key_path()}}
      )

      expect :crypto |> to(accepted :ensure_engine_loaded, :any, count: 1)
    end
  end

  context "pubkey:" do
    # Haven't found a good way to test this yet. Mocking this deep into X509
    # isn't valuable.
    it "returns a public key from an engine key ref (privkey)"
  end

  context "csr:" do
    let :privkey, do: X509.PrivateKey.new_rsa(1024)

    it "returns a certificate signing request" do
      allow Crypto |> to(accept :pubkey, fn privkey ->
        X509.PublicKey.derive(privkey)
      end)

      Crypto.csr(privkey(), "SN12345", "Test Organization")
      |> X509.CSR.valid?
      |> should(eq true)

      expect Crypto |> to(accepted :pubkey, :any, count: 1)
    end
  end
end
