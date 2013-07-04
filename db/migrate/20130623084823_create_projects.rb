class CreateProjects < ActiveRecord::Migration
  def change
    create_table :projects do |t|
      t.integer :parent_id
      t.string :title
      t.text :description
      t.text :large_description
      t.text :bugzilla_products
      t.text :git_repos
      t.text :mailing_lists
      t.text :irc_channels

      t.timestamps
    end
  end
end
