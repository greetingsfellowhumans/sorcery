defmodule Sorcery.Repo do
  alias Mix.EctoSQL
  use Ecto.Repo,
    otp_app: :sorcery,
    adapter: Ecto.Adapters.Postgres #Ecto.Adapter.Postgres
end
