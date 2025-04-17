defmodule StartupGame.Repo.Migrations.ConvertOwnershipChangesToDeltaBased do
  use Ecto.Migration
  import Ecto.Query

  def up do
    # 1. Add the percentage_delta column
    alter table(:ownership_changes) do
      add :percentage_delta, :decimal
    end

    # 2. Create a new index on round_id and position to maintain order
    create index(:ownership_changes, [:round_id, :inserted_at])

    # 3. Execute a function to calculate and populate the delta for all existing records
    execute """
    UPDATE ownership_changes
    SET percentage_delta = new_percentage - previous_percentage
    """

    # 4. Make the new column non-nullable after it's populated
    alter table(:ownership_changes) do
      modify :percentage_delta, :decimal, null: false
      modify :previous_percentage, :decimal, null: true
      modify :new_percentage, :decimal, null: true
    end

    # 5. Rename the existing columns to indicate they're deprecated but keep for backward compatibility
    rename table(:ownership_changes), :previous_percentage, to: :old_previous_percentage
    rename table(:ownership_changes), :new_percentage, to: :old_new_percentage
  end

  def down do
    # Revert all changes for rollback
    rename table(:ownership_changes), :old_previous_percentage, to: :previous_percentage
    rename table(:ownership_changes), :old_new_percentage, to: :new_percentage

    alter table(:ownership_changes) do
      remove :percentage_delta
    end

    drop index(:ownership_changes, [:round_id, :inserted_at])
  end
end
