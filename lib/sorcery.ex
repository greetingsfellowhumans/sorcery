defmodule Sorcery do
  @moduledoc """
  To get started with Sorcery, let's use the generator

  `mix sorcery.init`

  """


  defmacro __using__(opts) do
    quote do
      use Sorcery.SorceryDb, opts: unquote(opts)

      def config() do
        %{
          mutations: get_mod_map(:mutations, unquote(opts)),
          plugins: get_mod_map(:plugins, unquote(opts)),
          queries: get_mod_map(:queries, unquote(opts)),
          schemas: get_mod_map(:schemas, unquote(opts)),
        }
      end


      def get_mod_map(k, opts) do 
        sorcery_module_list = Module.split(__MODULE__) ++ [Macro.camelize("#{k}")]
        sorcery_module_len = Enum.count(sorcery_module_list)

        appname = Application.get_application(__MODULE__)
        {:ok, all_modules} = :application.get_key(appname, :modules)
        Enum.reduce(all_modules, %{}, fn module, acc ->
          strings = Module.split(module)
          if sorcery_module_list == Enum.slice(strings, 0, sorcery_module_len) do
            tk = Sorcery.Helpers.Names.mod_to_tk(module)
            Map.put(acc, tk, module)
          else
            acc
          end
        end)
      end


    end
  end

end
