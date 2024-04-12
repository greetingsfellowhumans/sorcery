defmodule Sorcery.Schema.EctoSchema do

  defmacro __using__([meta: %{ecto: false}]), do: nil

  defmacro __using__(opts) do

    quote bind_quoted: [opts: opts] do
      use Ecto.Schema
      import Ecto.Changeset

      tk = @meta[:tk]
      time = @meta[:timestamps]

      schema "#{tk}" do
        for {k, field_struct} <- @full_fields do
          field k, (Map.get(field_struct, :ecto_t) || field_struct.t), Map.take(field_struct, [:default, :source, :autogenerate, :read_after_writes, :virtual, :primary_key, :load_in_query, :redact, :skip_default_validation]) |> Enum.into([])
        end
        if time, do: timestamps()
      end

      def sorcery_insert_cs(body) do
        %__MODULE__{}
        |> cast(body, Map.keys(@schema))
      end

      def sorcery_update_cs(entity, body) do
        entity
        |> cast(body, Map.keys(@schema))
      end

      tk = nil
      time = nil
    end

  end

end
