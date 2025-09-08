class CommitComment < ApplicationRecord
  belongs_to :commit_metadatum
  validates :content, presence: true

  after_create :set_random_name

  def set_random_name
    update(author: "User #{rand(5000)}")
  end
end
