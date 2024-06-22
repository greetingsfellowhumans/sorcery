defmodule Sorcery.Schema.EctoSchema do
  @moduledoc false
  import Sorcery.Schema.EctoSchema.CastableFields

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
        body = gen_one(body)
        %__MODULE__{}
        #|> cast(body, Map.keys(@schema))
        |> cast(body, castable_fields(:insert, @full_fields))
        |> add_uniq_constraints(@full_fields)
      end

      def sorcery_update_cs(entity, body) do
        entity
        #|> cast(body, Map.keys(@schema))
        |> cast(body, castable_fields(:update, @full_fields))
        |> add_uniq_constraints(@full_fields)
      end

      # {{{ add_uniq_constraints
      defp add_uniq_constraints(cs, full_fields) do
        Enum.reduce(full_fields, cs, fn 
          {fk, %{unique: true}}, cs -> unique_constraint(cs, [fk])
          _, cs -> cs
        end)
      end
      # }}}


      tk = nil
      time = nil
    end

  end


end
