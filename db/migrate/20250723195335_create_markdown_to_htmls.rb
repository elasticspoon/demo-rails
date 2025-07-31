class CreateMarkdownToHtmls < ActiveRecord::Migration[8.0]
  def change
    create_table :markdown_to_htmls do |t|
      t.text :text

      t.timestamps
    end
  end
end
