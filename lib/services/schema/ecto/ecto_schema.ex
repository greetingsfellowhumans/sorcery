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
        #body = gen_one(body)
        %__MODULE__{}
        |> cast(body, castable_fields(:insert, @full_fields))
        |> add_uniq_constraints(@full_fields)
        |> add_required_validations(@full_fields)
        |> validate_size(@full_fields)
      end

      def sorcery_update_cs(entity, body) do
        entity
        |> cast(body, castable_fields(:update, @full_fields))
        |> add_uniq_constraints(@full_fields)
        |> add_required_validations(@full_fields)
        |> validate_size(@full_fields)
      end


      # {{{ validate_size
      defp validate_size(cs, full_fields) do
        Enum.reduce(full_fields, cs, fn 
          {fk, %{t: :string, min: minimum, max: maximum}}, cs when is_number(minimum) and is_number(maximum) -> validate_length(cs, fk, min: minimum, max: maximum)
          {fk, %{t: :string, min: minimum}}, cs when is_number(minimum) -> validate_length(cs, fk, min: minimum)
          {fk, %{t: :string, max: maximum}}, cs when is_number(maximum) -> validate_length(cs, fk, max: maximum)

          {fk, %{t: :integer, min: minimum, max: maximum}}, cs when is_number(minimum) and is_number(maximum)  -> validate_number(cs, fk, greater_than_or_equal_to: minimum, less_than_or_equal_to: maximum)
          {fk, %{t: :integer, min: minimum}}, cs when is_number(minimum) -> validate_number(cs, fk, greater_than_or_equal_to: minimum)
          {fk, %{t: :integer, max: maximum}}, cs when is_number(maximum) -> validate_number(cs, fk, less_than_or_equal_to: maximum)

          {fk, %{t: :float, min: minimum, max: maximum}}, cs when is_number(minimum) and is_number(maximum)  -> validate_number(cs, fk, greater_than_or_equal_to: minimum, less_than_or_equal_to: maximum)
          {fk, %{t: :float, min: minimum}}, cs when is_number(minimum) -> validate_number(cs, fk, greater_than_or_equal_to: minimum)
          {fk, %{t: :float, max: maximum}}, cs when is_number(maximum) -> validate_number(cs, fk, less_than_or_equal_to: maximum)
          _, cs -> cs
        end)
      end
      # }}}

      # {{{ add_required
      defp add_required_validations(cs, full_fields) do
        Enum.reduce(full_fields, cs, fn 
          {fk, %{optional?: false}}, cs -> 
            validate_required(cs, fk)
          {_fk, _deets}, cs -> cs
        end)
      end
      # }}}

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
