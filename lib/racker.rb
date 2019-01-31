# frozen_string_literal: true

class Racker
  attr_reader :request

  def self.call(env)
    new(env).response.finish
  end

  def initialize(env)
    @request = Rack::Request.new(env)
  end

  def response
    case @request.path
    when '/' then main_menu
    when '/start' then start
    when '/game' then game
    when '/rules', '/statistics' then static_pages
    when '/hint' then hint
    else Rack::Response.new(render('404'), 404)
    end
  end

  private

  def main_menu
    return show_page('game') if current_game

    show_page('menu')
  end

  def check_game_status
    return win if current_game.guess_won

    return lose if current_game.guess_loss

    show_page('game')
  end

  def static_pages
    return show_page(@request.path) unless current_game
  end

  def stats
    db = Codebreaker::Storage.new.load

    return false if db.size.zero?

    db.sort_by! { |x| [x[:attempts_total], x[:attempts_used], x[:hints_used]] }
  end

  def start
    return show_page('game') if current_game

    level = Difficulty.find(@request.params['level']).level

    @request.session[:game] = Codebreaker::Game.new(level)
    @request.session[:player] = @request.params['player_name']

    show_page('game')
  end

  def game
    return show_page('menu') unless session_present?
    return show_page('game') unless @request.params['number']

    current_game.guess(@request.params['number'])
    marks_view
    check_game_status
  end

  def win
    Rack::Response.new(show_page('win')) do
      current_game.save_result_game(current_player)
      destroy_session
    end
  end

  def lose
    Rack::Response.new(show_page('lose')) { destroy_session }
  end

  def hint
    return show_page('menu') unless session_present?

    current_game.hint

    show_page('game')
  end

  def marks(value)
    case value
    when '+' then { class: 'success', view: '+' }
    when '-' then { class: 'primary', view: '-' }
    else { class: 'danger', view: 'x' }
    end
  end

  def marks_view
    attempt_result = current_game.attempt_result
    @marks_guess = []

    return unless attempt_result.is_a?(Array)

    marks_total = attempt_result.size
    (1..4).each do |item|
      mark = marks_total >= item ? marks(attempt_result[item - 1]) : marks('x')

      @marks_guess.push("<button type='button' class='btn btn-#{mark[:class]} marks' disabled>#{mark[:view]}</button>")
    end
  end

  def current_player
    @request.session[:player]
  end

  def current_game
    @request.session[:game]
  end

  def session_present?
    @request.session.key?(:player)
  end

  def destroy_session
    @request.session.clear
  end

  def show_page(template)
    Rack::Response.new(render(template))
  end

  def render(template)
    path = File.expand_path("../views/#{template}.html.erb", __FILE__)
    ERB.new(File.read(path)).result(binding)
  end
end
