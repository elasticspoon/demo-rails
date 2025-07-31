class MarkdownToHtmlController < ApplicationController
  before_action :set_markdown, only: [ :create, :show ]
  def show
  end

  def new
    @markdown_to_html = MarkdownToHtml.new
  end

  def create
    binding.irb
    @markdown_to_html = MarkdownToHtml.build(markdown_params)

    if @markdown_to_html.save
        redirect_to @markdown_to_html
    else
        render :new, :unprocessable_entity
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_markdown
      @book = MarkdownToHtml.find(params.expect(:id))
    end

  def markdown_params
    params.expect(markdown_to_html: [ :text ])
  end
end
