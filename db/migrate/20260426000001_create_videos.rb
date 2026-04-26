class CreateVideos < ActiveRecord::Migration
  def change
    create_table :videos do |t|
      t.string  :youtube_id,     null: false
      t.string  :title
      t.string  :url,            null: false
      t.string  :thumbnail_url
      t.string  :author_name
      t.text    :embed_html
      t.text    :transcript
      t.datetime :ingested_at

      t.timestamps
    end

    add_index :videos, :youtube_id, unique: true
  end
end
