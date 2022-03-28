defmodule Sorcery.Storage.GenserverAdapter.Specs do
  @moduledoc false

  use Norm
  alias Sorcery.Specs.Primative, as: T

  def client_state(), do: schema(%{
    db: T.map(),
    presence: T.atom(),
    tables: T.map(),
    repo: T.atom(),
    ecto: T.atom(),
  })


  # Currently there is no way to spec a module.
  def client_module(), do: T.atom()
  def presence_module(), do: T.atom()

  def qmeta, do: spec(is_struct(Sorcery.Storage.GenserverAdapter.QueryMeta))

end
