defmodule Sorcery.Share.Watch do
  use Norm
  alias Sorcery.Specs.Primative, as: T
  alias Sorcery.Src.Subject

  @contract get_pids_from_changes(T.src(), T.presences()) :: coll_of(T.pid())
  def get_pids_from_changes(src, %{"src_subjects" => %{metas: presences}}) do
    Enum.reduce(presences, MapSet.new(), fn %{subject: sub, pid: pid}, acc ->
      if Subject.is_relevant?(sub, src) do
        MapSet.put(acc, pid)
      else
        acc
      end
    end)
  end

end
