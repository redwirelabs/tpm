defmodule TPM.TSS.Spec do
  use ESpec

  alias TPM.TSS

  let :path, do: "/tmp/key"

  context "genkey:" do
    it "generates a private key file" do
      allow MuonTrap |> to(accept :cmd, fn cmd, args, _opts ->
        cmd |> should(eq "tpm2tss-genkey")

        args |> should(have path())
        args |> should(have "-a")
        args |> should(have "rsa")
        args |> should(have "-t")
        args |> should(have "device:/dev/tpmrm0")

        {"", 0}
      end)

      TSS.genkey(path()) |> should(eq :ok)

      expect MuonTrap |> to(accepted :cmd, :any, count: 1)
    end

    it "returns an error if the key file can't be written" do
      allow MuonTrap |> to(accept :cmd, fn cmd, args, _opts ->
        cmd |> should(eq "tpm2tss-genkey")

        args |> should(have path())
        args |> should(have "-a")
        args |> should(have "rsa")
        args |> should(have "-t")
        args |> should(have "device:/dev/tpmrm0")

        {"Error writing file\n", 1}
      end)

      TSS.genkey(path()) |> should(match_pattern {:error, 1, _})

      expect MuonTrap |> to(accepted :cmd, :any, count: 1)
    end
  end
end
