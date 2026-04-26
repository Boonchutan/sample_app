class Video < ActiveRecord::Base
  attr_accessible :youtube_id, :title, :url, :thumbnail_url,
                  :author_name, :embed_html, :transcript, :ingested_at

  validates :youtube_id, presence: true, uniqueness: true
  validates :url,        presence: true

  def self.ingest(url)
    YoutubeIngestor.call(url)
  end

  def shorts_url
    "https://youtube.com/shorts/#{youtube_id}"
  end
end
