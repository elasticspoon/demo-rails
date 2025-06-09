class JiraTicketsController < ApplicationController
  def index
    @commit_metadatum = CommitMetadatum.find(params[:commit_metadatum_id])
    sleep 1
    @tickets = @commit_metadatum.jira_tickets
  end
end
