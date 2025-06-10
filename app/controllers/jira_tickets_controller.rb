class JiraTicketsController < ApplicationController
  before_action :set_ticket, except: [ :index, :new, :create ]
  before_action :set_commit_metadatum

  def index
    @new_ticket = JiraTicket.new(commit_metadata_id: @commit_metadatum.id)
    @tickets = @commit_metadatum.jira_tickets
  end

  def edit
    respond_to do |format|
      format.turbo_stream
      format.html
    end
  end

  def update
    respond_to do |format|
      if @ticket.update(ticket_params)
        format.turbo_stream
        format.html { redirect_to commit_metadatum_jira_tickets_path(@commit_metadatum) }
      else
        format.turbo_stream { render :update, status: :unprocessable_entity }
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def show
    respond_to do |format|
      format.turbo_stream
      format.html
    end
  end

  def destroy
    @ticket.destroy

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to commit_metadatum_jira_tickets_path(@commit_metadatum) }
    end
  end

  def new
    @ticket = JiraTicket.new(commit_metadata_id: params[:commit_metadatum_id])

    respond_to do |format|
      format.turbo_stream
      format.html
    end
  end

  def create
    @ticket = @commit_metadatum.jira_tickets.build(ticket_params)

    respond_to do |format|
      if @ticket.save
        format.turbo_stream
        format.html { redirect_to commit_metadatum_jira_tickets_path(@commit_metadatum) }
      else
        format.turbo_stream { render :create, status: :unprocessable_entity }
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  private

  def set_ticket
    @ticket = JiraTicket.find(params[:id])
  end

  def set_commit_metadatum
    @commit_metadatum = CommitMetadatum.find(params[:commit_metadatum_id])
  end

  def ticket_params
    params.require(:jira_ticket).permit(:ticket_number)
  end
end
