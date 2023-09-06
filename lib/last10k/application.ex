defmodule Last10k.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      Last10kWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Last10k.PubSub},
      # Start Finch
      {Finch, name: Last10k.Finch},
      # Start the Endpoint (http/https)
      Last10kWeb.Endpoint
      # Start a worker by calling: Last10k.Worker.start_link(arg)
      # {Last10k.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Last10k.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    Last10kWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
