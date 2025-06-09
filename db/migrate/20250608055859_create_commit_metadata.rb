class CreateCommitMetadata < ActiveRecord::Migration[8.0]
  def change
    create_table :commit_metadata do |t|
      t.string :sha, null: false
      t.string :repo_owner, null: false
      t.string :repo_name, null: false
      t.string :jira_url
      t.timestamps
    end

    add_index :commit_metadata, [ :sha, :repo_owner, :repo_name ], unique: true

    create_table :commit_comments do |t|
      t.references :commit_metadatum, null: false, foreign_key: true
      t.text :content
      t.text :author
      t.timestamps
    end
  end
end
