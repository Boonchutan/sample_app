class VideosController < ApplicationController
  def index
    @videos = Video.order('ingested_at DESC')
    @video  = Video.new
  end

  def show
    @video = Video.find(params[:id])
  end

  def create
    url = params[:url].to_s.strip
    if url.blank?
      redirect_to videos_path, alert: 'Please provide a YouTube URL.'
      return
    end

    @video = YoutubeIngestor.call(url)
    redirect_to video_path(@video), notice: 'Video ingested successfully.'
  rescue ArgumentError => e
    redirect_to videos_path, alert: e.message
  rescue ActiveRecord::RecordInvalid => e
    redirect_to videos_path, alert: "Could not save video: #{e.message}"
  rescue => e
    redirect_to videos_path, alert: "Ingestion failed: #{e.message}"
  end
end
