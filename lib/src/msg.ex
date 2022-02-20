defmodule Sorcery.Msg do

  defstruct [
    status: :ok,
    flash: "",
    body: nil,
    cb: &__MODULE__.noop/0
  ]


  def noop(), do: nil


  def error(body, flash) do
    %__MODULE__{
      flash: flash,
      status: :error,
      body: body,
      cb: fn -> IO.inspect(body, label: "ERROR FLASH >>>> #{flash} <<<<") end
    }
  end


  def success(flash) do
    %__MODULE__{
      flash: flash,
      status: :ok,
      body: nil,
      cb: &__MODULE__.noop/0
    }
  end


end
