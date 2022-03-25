defmodule ChatServer.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @spec start(any, any) :: {:error, any} | {:ok, pid}
  def start(_type, _args) do
    # List all child processes to be supervised
    port = String.to_integer(System.get_env("PORT") || "4040")
    children = [
      # {DynamicSupervisor, strategy: :one_for_one, name: ChatServer.Connection},
      {Task.Supervisor, name: ChatServer.TaskSupervisor},
      {Task, fn -> ChatServer.accept(port) end},
      {ChatServer.Worker, %{}},
      {ChatServer.Broadcast, []}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ChatServer.Supervisor,restart: :permanent]
    Supervisor.start_link(children, opts)
  end
end
