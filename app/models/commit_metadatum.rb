class CommitMetadatum < ApplicationRecord
  has_many :comments, class_name: "CommitComment", dependent: :destroy
  has_many :jira_tickets, foreign_key: "commit_metadata_id", dependent: :destroy, inverse_of: :commit_metadata

  validates :sha, :repo_owner, :repo_name, presence: true
  validates :sha, uniqueness: { scope: [ :repo_owner, :repo_name ] }
end
