class JiraTicketsController < ApplicationController
  def index
    @commit_metadatum = CommitMetadatum.find(params[:commit_metadatum_id])
    @tickets = @commit_metadatum.jira_tickets
  end

  def edit
    @ticket = JiraTicket.find(params[:id])
    @commit_metadatum = @ticket.commit_metadata

    respond_to do |format|
      format.turbo_stream
      format.html
    end
  end

  def update
    @ticket = JiraTicket.find(params[:id])
    @commit_metadatum = @ticket.commit_metadata

    if @ticket.update(ticket_params)
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to commit_metadatum_jira_tickets_path(@commit_metadatum) }
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def show
    @ticket = JiraTicket.find(params[:id])
    @commit_metadatum = @ticket.commit_metadata

    respond_to do |format|
      format.turbo_stream
      format.html
    end
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

  private

  def ticket_params
    params.require(:jira_ticket).permit(:ticket_number)
  end
end
