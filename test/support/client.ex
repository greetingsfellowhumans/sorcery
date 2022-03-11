defmodule Sorcery.Entities.User do
  defstruct [:id, :name, :karma]
end

defmodule Sorcery.Entities.Post do
  defstruct [:id, :title, :body, :author_id, :views]
end

defmodule Sorcery.Entities.Comment do
  defstruct [:id, :body, :author_id, :post_id, :likes]
end

defmodule Sorcery.Storage.GenserverAdapter.Client do
  alias Sorcery.Storage.GenserverAdapter
  alias Sorcery.Entities.{User, Post, Comment}

  use GenserverAdapter, %{
    presence: Sorcery.Storage.PresenceMock,
    ecto: :ecto_placeholder,
    repo: :repo_placeholder,
    tables: %{
      user: %{schema: User, index: []},
      post: %{schema: Post, index: [:author_id]},
      comment: %{schema: Comment, index: [:author_id, :post_id]},
    }
  }

end

