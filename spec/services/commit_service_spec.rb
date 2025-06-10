require 'rails_helper'

RSpec.describe CommitService do
  let(:valid_response) do
    double("Response",
      success?: true,
      parsed_response: [ {
        "sha" => "abc123",
        "html_url" => "http://example.com/commit/abc123",
        "commit" => {
          "message" => "Test commit",
          "author" => {
            "name" => "Test User",
            "date" => "2025-01-01T00:00:00Z"
          }
        }
      } ]
    )
  end

  describe ".recent_commits" do
    before do
      allow(GithubClient).to receive_message_chain(:new, :recent_commits)
        .and_return(valid_response)
    end

    it "builds commit objects from response" do
      commits = described_class.new.recent_commits
      expect(commits.first).to have_attributes(
        sha: "abc123",
        message: "Test commit",
        author_name: "Test User"
      )
    end

    it "returns empty array for unsuccessful response" do
      allow(GithubClient).to receive_message_chain(:new, :recent_commits)
        .and_return(double("Response", success?: false))
      expect(described_class.new.recent_commits).to eq([])
    end

    it "handles nil response" do
      allow(GithubClient).to receive_message_chain(:new, :recent_commits)
        .and_return(nil)
      expect(described_class.new.recent_commits).to eq([])
    end

    it "handles parsing errors gracefully" do
      allow(GithubClient).to receive_message_chain(:new, :recent_commits)
        .and_return(double("Response", success?: true, parsed_response: [ {} ]))
      expect(described_class.new.recent_commits).to eq([])
    end
  end
end
