class AddUntrackedToTransactions < ActiveRecord::Migration[8.1]
  def change
    add_column :transactions, :untracked, :boolean, default: false, null: false
  end
end
