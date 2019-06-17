defmodule InkyHostDev.MixProject do
  use Mix.Project

  def project do
    [
      app: :inky_host_dev,
      version: "0.0.1",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: [
        name: "inky_host_dev",
        description:
          "A development convenience for the Inky eInk display library. Allows rendering a window with largely the same behavior as the Inky display during host development. Built with the Erlang wxWidgets to avoid additional dependencies.",
        licenses: ["Apache-2.0"],
        links: %{"GitHub" => "https://github.com/pappersverk/inky_host_dev"}
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    []
  end
end
