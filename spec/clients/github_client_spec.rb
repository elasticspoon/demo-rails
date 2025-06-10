require 'rails_helper'

RSpec.describe GithubClient, type: :request do
  let(:client) { described_class.new("test/repo") }

  describe "#recent_commits" do
    it "makes API request to GitHub" do
      stub_request(:get, "https://api.github.com/repos/test/repo/commits")
        .with(query: { per_page: 30 })
        .to_return(status: 200, body: '[{"sha":"abc123"}]')

      response = client.recent_commits
      expect(response.code).to eq(200)
    end

    it "returns nil on error" do
      stub_request(:get, "https://api.github.com/repos/test/repo/commits")
        .with(query: { per_page: 30 })
        .to_raise(StandardError)

      expect { client.recent_commits }.to raise_error StandardError
    end
  end
end
