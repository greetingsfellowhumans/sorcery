defmodule Sorcery.StoreAdapter.Ecto.Query do
  @moduledoc false
  alias Sorcery.ReturnedEntities, as: RE
  alias Ecto.Multi, as: M
  alias Sorcery.StoreAdapter.Ecto.Query.BuildMulti
  import Sorcery.Helpers.Maps

  def run_query(inner_state, wheres, finds) do
    repo = inner_state.args.repo_module

    config = inner_state.config_module.config()
    tk_map = config.schemas
    ctx = %{
      repo: repo, 
      config: config, 
      tk_map: tk_map, 
      finds: finds, 
      wheres: wheres,
      multi: M.new()
    }
    ctx = BuildMulti.build_multi(ctx)
    case repo.transaction(ctx.multi) do
      {:ok, results} -> {:ok, transaction_to_re(results, ctx.wheres)}
      err -> {:error, err}
    end
  end

  # {{{ transaction_to_re
  defp transaction_to_re(transaction, wheres) do
    Enum.reduce(transaction, RE.new(), fn {lvark, li}, re ->
      RE.put_entities(re, "#{lvark}", li)
    end)
    |> add_lvar_tks(wheres)
  end


  defp add_lvar_tks(re, wheres) do
    Enum.reduce(wheres, re, fn %{tk: tk, lvar: lvar}, re ->
      put_in_p(re, [:lvar_tks, "#{lvar}"], tk)
    end)
  end
  # }}}



end
