class CommitCommentsController < ApplicationController
  def new
    @metadata = CommitMetadatum.find(params[:commit_metadatum_id])
    @comment = @metadata.comments.build

    respond_to do |format|
      format.turbo_stream
      format.html
    end
  end

  def create
    @metadata = CommitMetadatum.find(params[:commit_metadatum_id])
    @comment = @metadata.comments.build(comment_params)

    respond_to do |format|
      if @comment.save
        format.turbo_stream
        format.html { redirect_to commits_path, notice: "Comment added successfully" }
      else
        format.turbo_stream { render :new, status: :unprocessable_entity }
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  private

  def comment_params
    params.require(:commit_comment).permit(:content)
  end
end
