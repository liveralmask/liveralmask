class CreateSimpolleQuestions < ActiveRecord::Migration
  def change
    create_table :simpolle_questions do |t|
      t.text :question, null: false
      t.text :result, null: false
      t.integer :account_id, null: false

      t.timestamps null: false
      
      t.index :account_id, unique: false
    end
  end
end
