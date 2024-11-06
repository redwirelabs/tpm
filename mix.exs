defmodule Tpm.MixProject do
  use Mix.Project

  def project do
    [
      app: :tpm,
      version: "0.0.1",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      description: description(),
      package: package(),
      deps: deps(),
      docs: docs(),
      test_coverage: [tool: ExCoveralls, test_task: "espec"],
      dialyzer: [
        list_unused_filters: true,
        plt_file: {:no_warn, plt_file_path()},
      ],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        "coveralls.show": :test,
        espec: :test,
      ],
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp aliases do
    [
      "coveralls.show": ["coveralls.html", &open("cover/excoveralls.html", &1)],
      "docs.show": ["docs", &open("doc/index.html", &1)],
      test: "coveralls",
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:castore, "~> 1.0"},
      {:dialyxir, "~> 1.4", only: :dev, runtime: false},
      {:espec, "~> 1.9", only: :test},
      {:excoveralls, "~> 0.18", only: :test},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false},
      {:muontrap, "~> 1.5"},
      {:x509, "~> 0.8"},
    ]
  end

  defp description do
    """
    Use a Trusted Platform Module (TPM) with Elixir and Nerves
    """
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md", "LICENSE.txt"]
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/redwirelabs/tpm"},
      maintainers: ["Alex McLain"],
      files: [
        "lib",
        "mix.exs",
        "LICENSE.txt",
        "README.md",
      ]
    ]
  end

  # Open a file with the default application for its type.
  defp open(file, _args) do
    open_command =
      System.find_executable("xdg-open") # Linux
      || System.find_executable("open")  # Mac
      || raise "Could not find executable 'open' or 'xdg-open'"

    System.cmd(open_command, [file])
  end

  # Path to the dialyzer .plt file.
  defp plt_file_path do
    [Mix.Project.build_path(), "plt", "dialyxir.plt"]
    |> Path.join()
    |> Path.expand()
  end
end
