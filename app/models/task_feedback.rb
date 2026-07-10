class TaskFeedback < ApplicationRecord
    belongs_to :user
  validates :task_graph_id, presence: true

end
