defmodule Sorcery do
  alias Sorcery.Src
  @moduledoc """
  Documentation for `Sorcery`.
  """


  def new(db \\ %{}, args \\ %{}), do: %Src{original_db: db, args: args}

end
