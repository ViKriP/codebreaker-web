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
    when '/exit' then quit
    else Rack::Response.new(render('404'), 404)
    end
  end

  private

  def main_menu
    show_page('menu')
  end

  def check_game_status
    return win if current_game.guess_won

    return lose if current_game.guess_loss

    show_page('game')
  end

  def static_pages
    return show_page(@request.path) unless current_game

    check_game_existance
  end

  def start
    level = Difficulty.find(@request.params['level']).level

    @request.session[:game] = Codebreaker::Game.new(level)
    @request.session[:player] = current_game.secret_code#@request.params['player_name']

    show_page('game')
  end

  def game
    current_game.guess(@request.params['number'])
    marks_view
    check_game_status
  end

  def win
    Rack::Response.new(show_page('win')) do
      #Codebreaker::Storage.save(current_game)
      #@storage.save_game_result(start_game.to_h(user_name))
      destroy_session
    end
  end

  def lose
    Rack::Response.new(show_page('lose')) do
      destroy_session
    end
  end

  def hint
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
    puts attempt_result

    if attempt_result.is_a?(Array)
      marks_total = attempt_result.size
      (1..4).each { |item|
        marks_total >= item ? mark = marks(attempt_result[item-1]) : mark = marks('x')
        @marks_guess.push("<button type='button' class='btn btn-#{mark[:class]} marks' disabled>#{mark[:view]}</button>")
      }
    end
  end

  def quit
    destroy_session

    show_page('menu')
  end

  def current_player
    @request.session[:player]
  end

  def current_game
    @request.session[:game]
  end

  def session_param?(param)
    @request.session[param].nil?
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
