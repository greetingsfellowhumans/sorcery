defmodule Sorcery do
  @moduledoc """
  To get started with Sorcery, let's use the generator

  `mix sorcery.init`

  """


  defmacro __using__(opts) do
    quote do
#      @config %{
#        debug: Keyword.get(opts, :debug, false),
#        paths: Keyword.get(opts, :path, %{})
#      }

      def config() do
        %{
          schemas: get_mod_map(:schemas, unquote(opts)),
          queries: get_mod_map(:queries, unquote(opts)),
          mutations: get_mod_map(:mutations, unquote(opts)),
          modifications: get_mod_map(:modifications, unquote(opts)),
        }
      end


      defp get_mod_map(k, opts) do 
        paths = Keyword.get(opts, :paths, %{})
        if Map.has_key?(paths, k) do
          Sorcery.Helpers.Files.build_modules_map(paths[k], __MODULE__.Schemas)
        else
          %{}
        end
      end


    end
  end

end
