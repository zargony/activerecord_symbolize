class CreateTestingStructure < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      t.string :name, :so, :gui, :other, :status, :language, :kind
      t.string :limited, :limit => 10
      t.string :karma, :limit => 5
      t.boolean :sex
      t.boolean :public
      t.boolean :cool
    end
    create_table :user_skills do |t|
      t.references :user
      t.string :kind
    end
    create_table :user_extras do |t|
      t.references :user
      t.string :key, :null => false
    end
    create_table :permissions do |t|
      t.string :name
      t.string :key, :null => false
    end
  end

  def self.down
    drop_table :users
  end
end
