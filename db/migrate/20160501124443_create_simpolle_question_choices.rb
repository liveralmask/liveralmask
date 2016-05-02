class CreateSimpolleQuestionChoices < ActiveRecord::Migration
  def change
    create_table :simpolle_question_choices do |t|
      t.integer :simpolle_question_id, null: false
      t.integer :account_id, null: false
      t.integer :choice, null: false

      t.timestamps null: false
    end
    add_index :simpolle_question_choices, :simpolle_question_id
    add_index :simpolle_question_choices, :account_id
  end
end
