class CreateTestingStructure < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      t.string :name, :so, :gui, :other, :status, :language
      t.string :limited, :limit => 10
      t.boolean :sex
    end
    create_table :user_skills do |t|
      t.string :kind
    end
  end

  def self.down
    drop_table :users
  end
end
