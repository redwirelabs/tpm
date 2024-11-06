# TPM

Use a Trusted Platform Module (TPM) with Elixir and [Nerves](https://nerves-project.org/).

A TPM can be used to secure the cryptographic keys used for things like SSL/TLS
connections and disk encryption.

This library is mainly a wrapper around existing TPM libraries, which are
linked in the module docs of this repo. Documentation on how a TPM works can
be found there.

## Installation

This package can be installed by adding `tpm` to your list of dependencies
in `mix.exs`:

```elixir
def deps do
  [
    {:tpm, "~> 0.1.0"}
  ]
end
```

Copy the [tpm2-tss-engine](https://github.com/redwirelabs/nerves_system_iot_gate_imx8plus/tree/feature/tpm/package/tpm2-tss-engine)
package to your Nerves system if it does not exist.

Add the following to `nerves_defconfig`:

```kconfig
BR2_PACKAGE_TPM2_TOOLS=y
BR2_PACKAGE_TPM2_TOOLS_FAPI=y
BR2_PACKAGE_TPM2_TSS_ENGINE=y
```

## Usage

Generate a private key. Unlike a traditional private key file, this one requires
the TPM to function.

```ex
:ok = TPM.TSS.genkey("/data/.ssh/key")
```

A copy of the key can be stored in the TPM's non-volatile memory as a backup.
For example, if the device were factory reset and the disk wiped, the key could
be retrieved from the TPM's NV memory and its prior identity would be retained.

```ex
{:ok, address} = TPM.nvdefine(size: 1024)
:ok = TPM.nvwrite(address, "/data/.ssh/key")
```

The private key can be used within the BEAM VM by getting an [engine_key_ref](https://www.erlang.org/docs/22/man/crypto#type-engine_key_ref).

```ex
{:ok, privkey} = TPM.Crypto.privkey("/data/.ssh/key")
```

### Creating a certificate signing request

Some connections require the client to provide a signed certificate, or else
the connection will be rejected.

Generate a public key from the private key reference.

```ex
public_key_pem =
  privkey
  |> TPM.Crypto.pubkey
  |> X509.PublicKey.to_pem

File.write!("/data/.ssh/key.pub", public_key_pem)
```

Create the certificate signing request.

```ex
csr_pem =
  privkey
  |> TPM.Crypto.csr("Device ID", "My Organization")
  |> X509.CSR.to_pem

File.write!("/data/.ssh/csr.pem", csr_pem)
```

Copy the CSR from the device with `cat` on the device or `scp` on the host and
sign the CSR with the root or intermediate CA. Copy the signed certificate back
to the device. For some connections, concatenating the entire certificate bundle
into a file may be necessary.
