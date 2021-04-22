defmodule NsgLora.MixProject do
  use Mix.Project

  @rel_app [runtime_tools: :permanent, lorawan_server: :load]

  def project do
    [
      app: :nsg_lora,
      version: "0.1.0",
      elixir: "~> 1.7",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext, :rustler] ++ Mix.compilers(),
      rustler_crates: [
        nsglora_rust: [mode: if(Mix.env() == :dev, do: :debug, else: :release)]
      ],
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      releases: [
        local: [
          include_executables_for: [:unix],
          applications: @rel_app,
          runtime_config_path: "config/local.exs"
        ],
        nsg_lora_arm: [
          include_executables_for: [:unix],
          applications: @rel_app,
          include_erts: "/opt/erlang/arm_rt_eabi/erlang-22.3.4/erts-10.7.2",
          runtime_config_path: "config/target.exs",
          steps: [:assemble, :tar]
        ],
        nsg_lora_powerpc: [
          include_executables_for: [:unix],
          applications: @rel_app,
          include_erts: "/opt/erlang/powerpc_rt/erlang-22.3.4/erts-10.7.2",
          runtime_config_path: "config/target.exs",
          steps: [:assemble, :tar]
        ]
      ]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {NsgLora.Application, []},
      extra_applications: [:lager, :logger, :runtime_tools],
      erl_opts: [parse_transform: "lager_transform"]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.5.7"},
      {:phoenix_live_view, "~> 0.15.0"},
      {:floki, ">= 0.27.0", only: :test},
      {:phoenix_html, "~> 2.11"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_dashboard, "~> 0.4"},
      {:telemetry_metrics, "~> 0.4"},
      {:telemetry_poller, "~> 0.4"},
      {:gettext, "~> 0.11"},
      {:jason, "~> 1.0"},
      {:plug_cowboy, "~> 2.0"},

      # aditional deps
      {:memento, "~> 0.3.1"},
      {:guardian, "~> 2.0"},
      {:circular_buffer, "~> 0.3.0"},
      {:websockex, "~> 0.4.3"},
      {:geocalc, "~> 0.8"},
      {:rustler, "~> 0.22.0-rc.0"},

      # Для совместимости с lorawan-server
      {:ranch, "1.7.1", override: true},
      {
        :lorawan_server,
        git: "https://github.com/nsg-ru/lorawan-server.git", runtime: false
      },
      {:erlmongo,
       git: "https://github.com/SergejJurecko/erlmongo.git",
       ref: "f0d03cd4592f7bf28059b81214b61c28ccf046c0",
       override: true},
      {:cbor,
       git: "https://github.com/yjh0502/cbor-erlang.git",
       ref: "b5c9dbc2de15753b2db15e13d88c11738c2ac292",
       override: true},
      {:cowboy, "~> 2.8",
       env: :prod, hex: "cowboy", repo: "hexpm", optional: false, override: true},
      {:cowlib, git: "https://github.com/ninenines/cowlib", tag: "2.9.1", override: true}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "cmd npm install --prefix assets"],
      lora: ["cmd iex --sname lora1 -S mix phx.server"]
    ]
  end
end
