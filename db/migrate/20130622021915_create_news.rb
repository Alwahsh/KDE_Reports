class CreateNews < ActiveRecord::Migration
  def change
    create_table :news do |t|
      t.string :title
      t.text :content
      t.references :user

      t.timestamps
    end
    add_index :news, :user_id
  end
end
