class JiraTicketsController < ApplicationController
  def index
    @commit_metadatum = CommitMetadatum.find(params[:commit_metadatum_id])
    @tickets = @commit_metadatum.jira_tickets
  end

  def destroy
    @ticket = JiraTicket.find(params[:id])
    @commit_metadatum = @ticket.commit_metadata
    @ticket.destroy

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to commit_metadatum_jira_tickets_path(@commit_metadatum) }
    end
  end
end
