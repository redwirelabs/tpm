defmodule TPM.Spec do
  use ESpec

  let :address, do: "0x1C00001"

  context "clear:" do
    it "clears the TPM" do
      allow MuonTrap |> to(accept :cmd, fn cmd, args, _opts ->
        cmd |> should(eq "tpm2_clear")

        args |> should(have "-T")
        args |> should(have "device:/dev/tpmrm0")

        {"", 0}
      end)

      TPM.clear(confirm: true) |> should(eq :ok)

      expect MuonTrap |> to(accepted :cmd, :any, count: 1)
    end

    it "raises an exception if `confirm` is not set true" do
      expect fn ->
        TPM.clear(confirm: false)
      end |> to(raise_exception())
    end

    it "returns an error if the TPM is not present" do
      allow MuonTrap |> to(accept :cmd, fn cmd, args, _opts ->
        cmd |> should(eq "tpm2_clear")

        args |> should(have "-T")
        args |> should(have "device:/dev/tpmrm0")

        stdout = """
        ERROR:tcti:src/tss2-tcti/tcti-device.c:452:Tss2_Tcti_Device_Init() Failed to open specified TCTI device file /dev/tpmrm0: No such file or directory
        """

        {stdout, 1}
      end)

      TPM.clear(confirm: true) |> should(match_pattern {:error, 1, _})

      expect MuonTrap |> to(accepted :cmd, :any, count: 1)
    end
  end

  context "getcap handles_nv_index:" do
    it "returns a list of NV indices" do
      allow MuonTrap |> to(accept :cmd, fn cmd, args, _opts ->
        cmd |> should(eq "tpm2_getcap")

        args |> should(have "handles-nv-index")
        args |> should(have "-T")
        args |> should(have "device:/dev/tpmrm0")

        {"- 0x1900000\n- 0x1900001\n- 0x1900002\n", 0}
      end)

      TPM.getcap(:handles_nv_index)
      |> should(eq {:ok, ["0x1900000", "0x1900001", "0x1900002"]})

      expect MuonTrap |> to(accepted :cmd, :any, count: 1)
    end
  end

  context "nvdefine:" do
    it "allocates an NV index, chosen by the TPM" do
      allow MuonTrap |> to(accept :cmd, fn cmd, args, _opts ->
        cmd |> should(eq "tpm2_nvdefine")

        args |> should(have "-T")
        args |> should(have "device:/dev/tpmrm0")

        {"nv-index: #{address()}", 0}
      end)

      TPM.nvdefine |> should(eq {:ok, address()})

      expect MuonTrap |> to(accepted :cmd, :any, count: 1)
    end

    describe "allocates an NV index at a specified address" do
      specify do
        allow MuonTrap |> to(accept :cmd, fn cmd, args, _opts ->
          cmd |> should(eq "tpm2_nvdefine")

          args |> should(have address())
          args |> should(have "-T")
          args |> should(have "device:/dev/tpmrm0")

          {"nv-index: #{address()}", 0}
        end)

        TPM.nvdefine(address: address()) |> should(eq {:ok, address()})

        expect MuonTrap |> to(accepted :cmd, :any, count: 1)
      end

      it "returns an error if the address is already defined" do
        allow MuonTrap |> to(accept :cmd, fn cmd, args, _opts ->
          cmd |> should(eq "tpm2_nvdefine")

          args |> should(have address())
          args |> should(have "-T")
          args |> should(have "device:/dev/tpmrm0")

          stdout = """
          WARNING:esys:src/tss2-esys/api/Esys_NV_DefineSpace.c:344:Esys_NV_DefineSpace_Finish() Received TPM Error
          ERROR:esys:src/tss2-esys/api/Esys_NV_DefineSpace.c:122:Esys_NV_DefineSpace() Esys Finish ErrorCode (0x0000014c)
          ERROR: Failed to define NV area at index #{address()}
          ERROR: Esys_NV_DefineSpace(0x14C) - tpm:error(2.0): NV Index or persistent object already defined
          ERROR: Failed to create NV index #{address()}.
          ERROR: Unable to run tpm2_nvdefine
          """

          {stdout, 1}
        end)

        TPM.nvdefine(address: address()) |> should(match_pattern {:error, 1, _})

        expect MuonTrap |> to(accepted :cmd, :any, count: 1)
      end
    end

    describe "allocates an NV index with a specified size" do
      let :size, do: 4096

      specify do
        allow MuonTrap |> to(accept :cmd, fn cmd, args, _opts ->
          cmd |> should(eq "tpm2_nvdefine")

          args |> should(have "-s")
          args |> should(have to_string(size()))
          args |> should(have "-T")
          args |> should(have "device:/dev/tpmrm0")

          {"nv-index: #{address()}", 0}
        end)

        TPM.nvdefine(size: size()) |> should(eq {:ok, address()})

        expect MuonTrap |> to(accepted :cmd, :any, count: 1)
      end

      it "returns an error if the TPM is out of memory" do
        allow MuonTrap |> to(accept :cmd, fn cmd, args, _opts ->
          cmd |> should(eq "tpm2_nvdefine")

          args |> should(have "-s")
          args |> should(have to_string(size()))
          args |> should(have "-T")
          args |> should(have "device:/dev/tpmrm0")

          stdout = """
          WARNING:esys:src/tss2-esys/api/Esys_NV_DefineSpace.c:344:Esys_NV_DefineSpace_Finish() Received TPM Error
          ERROR:esys:src/tss2-esys/api/Esys_NV_DefineSpace.c:122:Esys_NV_DefineSpace() Esys Finish ErrorCode (0x000002d5)
          ERROR: Failed to define NV area at index #{address()}
          ERROR: Esys_NV_DefineSpace(0x2D5) - tpm:parameter(2):structure is the wrong size
          ERROR: Failed to create NV index #{address()}.
          ERROR: Unable to run tpm2_nvdefine
          """

          {stdout, 1}
        end)

        TPM.nvdefine(size: size()) |> should(match_pattern {:error, 1, _})

        expect MuonTrap |> to(accepted :cmd, :any, count: 1)
      end
    end
  end

  context "nvread:" do
    it "returns the contents at an NV index" do
      allow MuonTrap |> to(accept :cmd, fn cmd, args, _opts ->
        cmd |> should(eq "tpm2_nvread")

        args |> should(have address())
        args |> should(have "-T")
        args |> should(have "device:/dev/tpmrm0")

        {"hello world", 0}
      end)

      TPM.nvread(address()) |> should(eq {:ok, "hello world"})

      expect MuonTrap |> to(accepted :cmd, :any, count: 1)
    end

    let :output_file, do: "/tmp/nv"
    it "reads an NV index and writes the contents to a file" do
      allow MuonTrap |> to(accept :cmd, fn cmd, args, _opts ->
        cmd |> should(eq "tpm2_nvread")

        args |> should(have address())
        args |> should(have "-o")
        args |> should(have output_file())
        args |> should(have "-T")
        args |> should(have "device:/dev/tpmrm0")

        {"", 0}
      end)

      TPM.nvread(address(), output: output_file())
      |> should(eq :ok)

      expect MuonTrap |> to(accepted :cmd, :any, count: 1)
    end

    it "returns an error if the address does not exist" do
      allow MuonTrap |> to(accept :cmd, fn cmd, args, _opts ->
        cmd |> should(eq "tpm2_nvread")

        args |> should(have address())
        args |> should(have "-o")
        args |> should(have output_file())
        args |> should(have "-T")
        args |> should(have "device:/dev/tpmrm0")

        stdout = """
        WARN: Reading full size of the NV index
        WARNING:esys:src/tss2-esys/api/Esys_NV_ReadPublic.c:309:Esys_NV_ReadPublic_Finish() Received TPM Error
        ERROR:esys:src/tss2-esys/esys_tr.c:243:Esys_TR_FromTPMPublic_Finish() Error NV_ReadPublic ErrorCode (0x0000018b)
        ERROR:esys:src/tss2-esys/esys_tr.c:402:Esys_TR_FromTPMPublic() Error TR FromTPMPublic ErrorCode (0x0000018b)
        ERROR: Esys_TR_FromTPMPublic(0x18B) - tpm:handle(1):the handle is not correct for the use
        ERROR: Invalid handle authorization.
        ERROR: Unable to run /usr/bin/tpm2_nvread
        """

        {stdout, 1}
      end)

      TPM.nvread(address(), output: output_file())
      |> should(match_pattern {:error, 1, _})

      expect MuonTrap |> to(accepted :cmd, :any, count: 1)
    end
  end

  context "nvwrite:" do
    let :path, do: "/tmp/nv"

    it "writes a file to an NV address" do
      allow MuonTrap |> to(accept :cmd, fn cmd, args, _opts ->
        cmd |> should(eq "tpm2_nvwrite")

        args |> should(have address())
        args |> should(have "-i")
        args |> should(have path())
        args |> should(have "-T")
        args |> should(have "device:/dev/tpmrm0")

        {"", 0}
      end)

      TPM.nvwrite(address(), path()) |> should(eq :ok)

      expect MuonTrap |> to(accepted :cmd, :any, count: 1)
    end

    it "returns an error if the address does not exist" do
      allow MuonTrap |> to(accept :cmd, fn cmd, args, _opts ->
        cmd |> should(eq "tpm2_nvwrite")

        args |> should(have address())
        args |> should(have "-i")
        args |> should(have path())
        args |> should(have "-T")
        args |> should(have "device:/dev/tpmrm0")

        stdout = """
        WARNING:esys:src/tss2-esys/api/Esys_NV_ReadPublic.c:309:Esys_NV_ReadPublic_Finish() Received TPM Error
        ERROR:esys:src/tss2-esys/esys_tr.c:243:Esys_TR_FromTPMPublic_Finish() Error NV_ReadPublic ErrorCode (0x0000018b)
        ERROR:esys:src/tss2-esys/esys_tr.c:402:Esys_TR_FromTPMPublic() Error TR FromTPMPublic ErrorCode (0x0000018b)
        ERROR: Esys_TR_FromTPMPublic(0x18B) - tpm:handle(1):the handle is not correct for the use
        ERROR: Failed to write NVRAM public area at index #{address()}
        Usage: tpm2_nvwrite [<options>] <arguments>
        Where <options> are:
            [ -C | --hierarchy=<value>] [ -P | --auth=<value>] [ -i | --input=<value>] [ --offset=<value>]
            [ --cphash=<value>]
        """

        {stdout, 2}
      end)

      TPM.nvwrite(address(), path())
      |> should(match_pattern {:error, :invalid_options, _})

      expect MuonTrap |> to(accepted :cmd, :any, count: 1)
    end
  end
end
