class CreateBananas < ActiveRecord::Migration
  def self.up
    create_table :bananas, :force => true do |t|
      t.string :description, :color
      t.float :weight
      t.timestamps
    end
  end

  def self.down
    drop_table :bananas
  end
end