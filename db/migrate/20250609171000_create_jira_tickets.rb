class CreateJiraTickets < ActiveRecord::Migration[8.0]
  def change
    create_table :jira_tickets do |t|
      t.string :ticket_number
      t.references :commit_metadata, null: false, foreign_key: true

      t.timestamps
    end
  end
end
