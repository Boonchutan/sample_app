namespace :ingest do
  desc "Ingest a YouTube Short: rake ingest:youtube_short URL=https://youtube.com/shorts/ID"
  task youtube_short: :environment do
    url = ENV['URL'].to_s.strip
    abort "Usage: rake ingest:youtube_short URL=<youtube_shorts_url>" if url.blank?

    puts "Ingesting: #{url}"
    video = YoutubeIngestor.call(url)
    puts "Saved video ##{video.id}: #{video.title}"
    puts "YouTube ID:  #{video.youtube_id}"
    puts "Author:      #{video.author_name}"
    puts "Thumbnail:   #{video.thumbnail_url}"
    if video.transcript.present?
      puts "\n--- Transcript ---"
      puts video.transcript
    else
      puts "\n(No transcript — yt-dlp or whisper may not be available)"
    end
  end
end
