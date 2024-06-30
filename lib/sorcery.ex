defmodule Sorcery do
  @moduledoc """
  To get started with Sorcery, let's use the generator

  `mix sorcery.init`

  By default it creates a new namespace 'Src' in your app.
  The src.ex module is very special, it starts up some :ets/:mnesia tables, as well as holds together some config for making everything else work.

  You can manually create your own with 
  ```elixir
  defmodule MyApp.Src do
    use Sorcery
  end
  ```
  And then make sure your queries and schemas, etc. are all namespaced below that like `MyApp.Src.Queries.GetStuff` and 'MyApp.Src.Schemas.Thing'
  """


  defmacro __using__(opts) do
    quote do
      use Sorcery.SorceryDb, opts: unquote(opts)

      @debug? Keyword.get(unquote(opts), :debug, false)
      def debug?(), do: @debug?

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
