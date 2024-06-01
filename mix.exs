defmodule JsonpathToAccess.MixProject do
  use Mix.Project

  def project do
    [
      app: :jsonpath_to_access,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  def package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/thomas9911/jsonpath-to-access"},
      description: "Library to convert a JSONPath expression into an access path"
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:combine, "~> 0.10.0"},
      {:dialyxir, "~> 1.4.3", only: [:dev], runtime: false},
      {:ex_doc, "~> 0.34.0", only: [:dev], runtime: false}
    ]
  end
end
