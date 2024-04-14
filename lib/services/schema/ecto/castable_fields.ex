defmodule Sorcery.Schema.EctoSchema.CastableFields do


  def castable_fields(:insert, schema) do
    Enum.reduce(schema, [], fn {k, attrs}, li ->
      castable? = case attrs do
        %{insert_cast?: true} -> true
        %{insert_cast?: false} -> false
        %{cast?: false} -> false
        _ -> true
      end

      if castable?, do: [k | li], else: li
    end)
  end


  def castable_fields(:update, schema) do
    Enum.reduce(schema, [], fn {k, attrs}, li ->
      castable? = case attrs do
        %{update_cast?: true} -> true
        %{update_cast?: false} -> false
        %{cast?: false} -> false
        _ -> true
      end

      if castable?, do: [k | li], else: li
    end)
  end

  
end
