class Commit
  attr_reader :sha, :message, :author_name, :date, :url, :repo_owner, :repo_name, :metadata

  def initialize(attributes = {})
    @sha = attributes[:sha]
    @message = attributes[:message]
    @author_name = attributes[:author_name]
    @date = attributes[:date]
    @url = attributes[:url]
    @repo_owner = attributes[:repo_owner]
    @repo_name = attributes[:repo_name]
    @metadata = attributes[:metadata]
  end

  def formatted_date
    date.strftime("%B %d, %Y %H:%M") if date
  end

  def short_message
    message.split("\n").first if message
  end
end
