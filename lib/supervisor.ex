defmodule Sorcery.Supervisor do
  use Supervisor


  def init(opts) do
    IO.inspect(opts, label: "Init Sorcery Supervisor")
    children = []
    Supervisor.init(children, strategy: :one_for_one)
  end


end
