defmodule Sorcery.Application do
  use Application
  
  @impl true
  def start(_start_type, _start_args) do
    children = if Mix.env() == :test do
      [
        Sorcery.Repo
      ]
    else
      []
    end
    opts = [strategy: :one_for_one, name: Sorcery.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

