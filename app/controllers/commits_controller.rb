class CommitsController < ApplicationController
  def index
    @commits = CommitService.new.recent_commits
  rescue StandardError => e
    Rails.logger.error "Commits loading failed: #{e.message}"
    @commits = []
  end
end
