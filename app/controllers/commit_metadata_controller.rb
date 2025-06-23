class CommitMetadataController < ApplicationController
  def update
    @commit_metadatum = CommitMetadatum.find(params[:id])
    if @commit_metadatum.update(commit_metadatum_params)
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to commits_path, notice: "Deployment status updated" }
      end
    else
      head :unprocessable_entity
    end
  end

  private

  def commit_metadatum_params
    params.require(:commit_metadatum).permit(:safe_to_deploy)
  end
end
