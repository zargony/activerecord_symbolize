class CreateTestingStructure < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      t.string :name
      t.string :other
      t.string :status
      t.string :so
    end
  end

  def self.down
    drop_table :users
  end
end
