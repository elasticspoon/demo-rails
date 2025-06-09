class CommitService
  PER_PAGE = 30
  attr_reader :repo

  def initialize(repo: "rubyforgood/casa")
    @repo = repo
  end

  def recent_commits
    response = GithubClient.new(repo).recent_commits(limit: PER_PAGE)
    return [] unless response&.success?

    response.parsed_response.map do |commit_data|
      repo_owner, repo_name = repo.split('/')
      sha = commit_data["sha"]
      
      metadata = CommitMetadatum.find_or_initialize_by(
        sha: sha,
        repo_owner: repo_owner,
        repo_name: repo_name
      )
      metadata.parse_jira_tickets(commit_data.dig("commit", "message"))
      metadata.save! if metadata.changed?

      Commit.new(
        sha: sha,
        message: commit_data.dig("commit", "message"),
        author_name: commit_data.dig("commit", "author", "name"),
        date: Time.parse(commit_data.dig("commit", "author", "date")),
        url: commit_data["html_url"],
        repo_owner: repo_owner,
        repo_name: repo_name,
        metadata: metadata
      )
    end
  rescue StandardError => e
    Rails.logger.error "Commit building failed: #{e.message}"
    []
  end
end
