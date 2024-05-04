defmodule Sorcery.Schema.FieldType do
  @moduledoc """
  WIP
  currently it is not possible to add your own custom field types. But in the future it should be possible since they all follow this behaviour
  """
  alias Sorcery.Schema.FieldType, as: FT
  
  @callback new(map()) :: struct()

  def new(%{t: t} = args, meta) do
    mod = case t do
      :integer -> FT.Integer
      :string -> FT.String
      :fk -> FT.Fk
    end
    args = Map.put_new(args, :optional?, meta.optional?)
    mod.new(args)
  end
  def new(_) do
    raise "You will need to add a :t attr to your schema field. Like t: integer or t: :string, etc."
  end



  @doc """
  For example the Integer type would return n&is_integer/1
  """
  @callback base_norm_spec() :: function()


  @doc """
  During validation of a field, we go through every attribute, comparing it to the given value to see if everything is valid.

  We do it this way to try to keep everything related to attributes all in one place - the field struct.
  For example, if you look in Sorcery.Schema.FieldType.Integer, you will find a defstruct that lists several attributes. 
  But there is also the is_valid? function, with a different head for each one.
  """
  @callback is_valid?(attr_k :: atom(), attr_v :: any(), value :: any()) :: boolean()

  @callback get_sd_field(struct()) :: %StreamData{}
end
