defmodule Sorcery do
  @moduledoc """
  To get started with Sorcery, let's use the generator

  `mix sorcery.init`

  """

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do

      @config %{
        debug: Keyword.get(opts, :debug, false),
        paths: %{
          schemas:        Keyword.get(opts, :schemas, %{}),
          queries:        Keyword.get(opts, :queries, %{}),
          mutations:      Keyword.get(opts, :mutations, %{}),
          modifications:  Keyword.get(opts, :modifications, %{}),
          portal_servers: Keyword.get(opts, :portal_servers, %{}),
          plugins:        Keyword.get(opts, :plugins, %{}),
        }
      }

      def config(), do: @config

    end
  end

end
