require 'net/http'
require 'json'
require 'open3'
require 'tmpdir'

class YoutubeIngestor
  OEMBED_URL = 'https://www.youtube.com/oembed'

  def self.call(url)
    new(url).ingest
  end

  def initialize(url)
    @url = url.strip
  end

  def ingest
    youtube_id = extract_youtube_id(@url)
    raise ArgumentError, "Cannot extract YouTube ID from: #{@url}" unless youtube_id

    video = Video.find_or_initialize_by(youtube_id: youtube_id)
    return video if video.persisted? && video.transcript.present?

    meta = fetch_oembed(youtube_id)

    video.assign_attributes(
      url:           @url,
      title:         meta['title'],
      thumbnail_url: meta['thumbnail_url'],
      author_name:   meta['author_name'],
      embed_html:    meta['html'],
      ingested_at:   Time.now
    )

    transcript = transcribe(youtube_id)
    video.transcript = transcript if transcript

    video.save!
    video
  end

  private

  def extract_youtube_id(url)
    # Shorts: youtube.com/shorts/ID
    if url =~ %r{youtube\.com/shorts/([A-Za-z0-9_-]{11})}
      return $1
    end
    # Standard: youtube.com/watch?v=ID or youtu.be/ID
    if url =~ /[?&]v=([A-Za-z0-9_-]{11})/
      return $1
    end
    if url =~ %r{youtu\.be/([A-Za-z0-9_-]{11})}
      return $1
    end
    nil
  end

  def fetch_oembed(youtube_id)
    video_url = "https://www.youtube.com/shorts/#{youtube_id}"
    uri = URI(OEMBED_URL)
    uri.query = URI.encode_www_form(url: video_url, format: 'json')
    response = Net::HTTP.get_response(uri)
    raise "oEmbed request failed: #{response.code}" unless response.is_a?(Net::HTTPSuccess)
    JSON.parse(response.body)
  rescue => e
    Rails.logger.warn "YoutubeIngestor: oEmbed fetch failed — #{e.message}"
    {}
  end

  def transcribe(youtube_id)
    Dir.mktmpdir do |tmpdir|
      audio_path = File.join(tmpdir, "#{youtube_id}.%(ext)s")
      shorts_url = "https://www.youtube.com/shorts/#{youtube_id}"

      download_out, download_err, download_status = Open3.capture3(
        'yt-dlp', '--no-check-certificate', '-x', '--audio-format', 'mp3',
        '--no-playlist', '-o', audio_path, shorts_url
      )

      unless download_status.success?
        Rails.logger.warn "YoutubeIngestor: yt-dlp failed — #{download_err}"
        return nil
      end

      mp3 = Dir.glob(File.join(tmpdir, "#{youtube_id}.*")).first
      return nil unless mp3 && File.exist?(mp3)

      transcript_out, transcript_err, transcript_status = Open3.capture3(
        'python3', '-c',
        <<~PYTHON, mp3
          import sys, whisper
          model = whisper.load_model("base")
          result = model.transcribe(sys.argv[1])
          print(result["text"])
        PYTHON
      )

      unless transcript_status.success?
        Rails.logger.warn "YoutubeIngestor: whisper failed — #{transcript_err}"
        return nil
      end

      transcript_out.strip.presence
    end
  rescue => e
    Rails.logger.warn "YoutubeIngestor: transcription error — #{e.message}"
    nil
  end
end
