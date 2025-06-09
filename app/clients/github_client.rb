class GithubClient
  include HTTParty
  base_uri "https://api.github.com"

  def initialize(repo)
    @repo = repo
  end

  def recent_commits(limit: 30)
    self.class.get("/repos/#{@repo}/commits",
      headers: { "Accept" => "application/vnd.github.v3+json" },
      query: { per_page: limit }
    )
  end
end
