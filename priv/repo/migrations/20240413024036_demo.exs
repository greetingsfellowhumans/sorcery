defmodule Sorcery.Repo.Migrations.Demo do
  use Ecto.Migration

  def change do
    if Mix.env() == :test do
      create table("battle_arena") do
        add :name,   :string
      end

      create table("team") do
        add :name,   :string
        add :location_id, references("battle_arena")
      end
      drop_if_exists constraint("team", "team_location_id_fkey")

      create table("player") do
        add :name,      :string
        add :a_list,    {:array, :integer}
        add :team_id,   references("team")
        add :health,    :integer
        add :mana,      :integer
        add :age,       :integer
        add :money,     :integer
      end

      create table("spell_type") do
        add :name,      :string
        add :cost,      :integer
        add :power,     :integer
        add :coin_flip, :boolean
      end

      create table("spell_instance") do
        add :player_id, references("player")
        add :type_id, references("spell_type")
      end

      create table("types") do
        add :int1, :integer
      end

    end
  end

end
