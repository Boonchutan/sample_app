class FlashcardController < ApplicationController

  ASANAS = [
    "Samasthitih",
    "Surya Namaskara A",
    "Surya Namaskara B",
    "Padangusthasana",
    "Pada Hastasana",
    "Utthita Trikonasana",
    "Parivritta Trikonasana",
    "Utthita Parsvakonasana",
    "Parivritta Parsvakonasana",
    "Prasarita Padottanasana A",
    "Prasarita Padottanasana B",
    "Prasarita Padottanasana C",
    "Prasarita Padottanasana D",
    "Parsvottanasana",
    "Utthita Hasta Padangusthasana",
    "Ardha Baddha Padmottanasana",
    "Utkatasana",
    "Virabhadrasana A",
    "Virabhadrasana B",
    "Dandasana",
    "Paschimottanasana A",
    "Paschimottanasana B",
    "Paschimottanasana C",
    "Purvattanasana",
    "Ardha Baddha Padma Paschimottanasana",
    "Tiriang Mukha Ekapada Paschimottanasana",
    "Janu Sirsasana A",
    "Janu Sirsasana B",
    "Janu Sirsasana C",
    "Marichyasana A",
    "Marichyasana B",
    "Marichyasana C",
    "Marichyasana D",
    "Navasana",
    "Bhujapidasana",
    "Kurmasana",
    "Supta Kurmasana",
    "Garbha Pindasana",
    "Kukkutasana",
    "Baddha Konasana A",
    "Baddha Konasana B",
    "Upavishta Konasana A",
    "Upavishta Konasana B",
    "Supta Konasana",
    "Supta Padangusthasana A",
    "Supta Padangusthasana B",
    "Ubhaya Padangusthasana",
    "Urdhva Mukha Paschimottanasana",
    "Setu Bandhasana",
    "Urdhva Dhanurasana",
    "Salamba Sarvangasana",
    "Halasana",
    "Karnapidasana",
    "Urdhva Padmasana",
    "Pindasana",
    "Matsyasana",
    "Uttana Padasana",
    "Sirsasana A",
    "Sirsasana B",
    "Baddha Padmasana",
    "Padmasana",
    "Utpluthih",
    "Lay Down"
  ].freeze

  def index
    session[:score] ||= 0
    session[:total] ||= 0
    load_card
  end

  def check
    card_index = session[:card_index].to_i
    direction  = session[:ask_direction]
    answer     = params[:answer].to_s.strip

    correct = direction == "before" ? ASANAS[card_index - 1] : ASANAS[card_index + 1]

    session[:total] = session[:total].to_i + 1

    if answer.downcase == correct.downcase
      session[:score] = session[:score].to_i + 1
      flash[:success] = "Correct! \"#{correct}\" comes #{direction} #{ASANAS[card_index]}."
    else
      flash[:error] = "Not quite! The asana #{direction} #{ASANAS[card_index]} is \"#{correct}\"." \
                      " You answered: \"#{answer.empty? ? '(blank)' : answer}\""
    end

    # Generate a new card (exclude first and last so there's always a before/after)
    session[:card_index]    = rand(1..(ASANAS.length - 2))
    session[:ask_direction] = %w[before after].sample

    redirect_to flashcard_path
  end

  def reset
    session[:score]         = 0
    session[:total]         = 0
    session[:card_index]    = nil
    session[:ask_direction] = nil
    redirect_to flashcard_path
  end

  private

  def load_card
    session[:card_index]    ||= rand(1..(ASANAS.length - 2))
    session[:ask_direction] ||= %w[before after].sample

    @card_index    = session[:card_index]
    @ask_direction = session[:ask_direction]
    @card_asana    = ASANAS[@card_index]
    @score         = session[:score].to_i
    @total         = session[:total].to_i
  end
end
