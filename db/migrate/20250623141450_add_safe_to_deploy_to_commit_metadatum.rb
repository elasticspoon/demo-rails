class AddSafeToDeployToCommitMetadatum < ActiveRecord::Migration[8.0]
  def change
    add_column :commit_metadata, :safe_to_deploy, :boolean, default: false, null: false
  end
end
