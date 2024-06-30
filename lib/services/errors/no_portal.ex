defmodule Sorcery.NoPortalInStateError do
  defexception [:portal_name, :available_names]


  @impl true
  def message(value) do
    name = value.portal_name
    avail = 
      value.available_names 
      |> Enum.map(&(":#{&1}"))
      |> Enum.join("\n  ")
    ~s"""



    There is no portal named :#{name}. 
    Available portals:

    #{avail}

    """
  end

  @impl true
  def exception(value) do
    struct(Sorcery.NoPortalInStateError, value)
  end


end
defmodule Sorcery.NoPortalError do
  defexception [message: "Expected a portal but received a nil"]


  @impl true
  def message(_) do
    "No portal exists there"
  end

  @impl true
  def exception(_value) do
    %Sorcery.NoPortalError{}
  end


end
