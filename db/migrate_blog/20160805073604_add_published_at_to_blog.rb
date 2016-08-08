class AddPublishedAtToBlog < ActiveRecord::Migration
  def change
    add_column :blogs, :published_at, :datetime
  end
end
