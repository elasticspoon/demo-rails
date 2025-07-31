class MarkdownToHtmlsController < ApplicationController
  before_action :set_markdown_to_html, only: %i[ show edit update destroy ]

  # GET /markdown_to_htmls
  def index
    @markdown_to_htmls = MarkdownToHtml.all
  end

  # GET /markdown_to_htmls/1
  def show
  end

  # GET /markdown_to_htmls/new
  def new
    @markdown_to_html = MarkdownToHtml.new
  end

  # GET /markdown_to_htmls/1/edit
  def edit
  end

  # POST /markdown_to_htmls
  def create
    text = params[:markdown_to_html][:text]
    @markdown_to_html = MarkdownToHtml.new(text:)

    if @markdown_to_html.save
      redirect_to @markdown_to_html, notice: "Markdown to html was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /markdown_to_htmls/1
  def update
    if @markdown_to_html.update(markdown_to_html_params)
      redirect_to @markdown_to_html, notice: "Markdown to html was successfully updated.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /markdown_to_htmls/1
  def destroy
    @markdown_to_html.destroy!
    redirect_to markdown_to_htmls_path, notice: "Markdown to html was successfully destroyed.", status: :see_other
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_markdown_to_html
      @markdown_to_html = MarkdownToHtml.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def markdown_to_html_params
    binding.irb
      params.permit(:markdown_to_html).require(:text)
    end
end
