class CreateComments < ActiveRecord::Migration[4.2]
  def self.up
    create_table :comments do |t|
      t.integer :owner_id,         :null => false
      t.integer :commentable_id,   :null => false
      t.string  :commentable_type, :null => false
      t.text    :body,             :null => false
      t.timestamps
    end
  end

  def self.down
    drop_table :comments
  end
end
