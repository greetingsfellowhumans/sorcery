defmodule Sorcery.Repo do
  use Ecto.Repo,
    otp_app: :sorcery,
    adapter: Ecto.Adapters.Postgres
end
