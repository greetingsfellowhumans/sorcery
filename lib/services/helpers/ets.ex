defmodule Sorcery.Helpers.Ets do
  @moduledoc false

  #Wrapper around :ets.new()
  #Only calls it if the table does not exist
  def ensure_table(table, opts) do
    case :ets.info(table) do
      :undefined -> :ets.new(table, opts)
      _ -> :noop
    end
  end


end
