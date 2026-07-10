class CreateTaskFeedbacks < ActiveRecord::Migration[7.0]
  def change
    create_table :task_feedbacks do |t|
      t.integer :task_graph_id
      t.integer :user_id
      t.float :actual_duration
      t.integer :satisfaction
      t.text :comments

      t.timestamps
    end
  end
end
