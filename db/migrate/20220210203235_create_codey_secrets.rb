class CreateCodeySecrets < ActiveRecord::Migration[7.0]
  def change
    create_table :codey_secrets do |t|
      t.string :salt
      t.datetime :expires_at
      t.text :encrypted_data
      t.integer :remaining_attempts

      t.timestamps
    end
  end
end
