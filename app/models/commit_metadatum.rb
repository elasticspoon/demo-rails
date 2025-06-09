class CommitMetadatum < ApplicationRecord
  has_many :comments, class_name: 'CommitComment', dependent: :destroy
  validates :sha, :repo_owner, :repo_name, presence: true
  validates :sha, uniqueness: { scope: [:repo_owner, :repo_name] }
end
