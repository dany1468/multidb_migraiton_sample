class CreateBlog < ActiveRecord::Migration
  def change
    create_table :blogs do |t|
      t.string :title, null: false
    end
  end
end
