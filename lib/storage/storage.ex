defmodule Sorcery.Storage do
  @moduledoc """
  Client should call something like
  use Sorcery.Storage, [
    adapter: MementoAdapter,
    tables: %{
      tk: %{attributes: [], schema: Schema, index: []}
    }
  ]
  """

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do

      IO.inspect(opts, label: "Ok just... loose?")

      def start_link(opts) do
        IO.inspect(opts, label: "Sorcery.Storage.start_link(opts)")
        Sorcery.StorageSupervisor.start_link(__MODULE__, opts)
      end

      def child_spec(opts) do
        %{
          id: __MODULE__,
          start: {__MODULE__, :start_link, [opts]},
          type: :supervisor
        }
      end


    end
  end

end
