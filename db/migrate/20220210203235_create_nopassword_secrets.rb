class CreateNoPasswordSecrets < ActiveRecord::Migration[7.0]
  def change
    create_table :nopassword_secrets do |t|
      t.string :data_digest, null: false
      t.string :code_digest, null: false

      t.datetime :expires_at, null: false
      t.integer :remaining_attempts, null: false

      t.index :data_digest, unique: true
      t.timestamps
    end
  end
end
