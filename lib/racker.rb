class Racker
  attr_reader :request, :game

  def self.call(env)
    new(env).response.finish
  end

  def initialize(env)
    @request = Rack::Request.new(env)
  end

  def response
    case @request.path
    when '/', '/win', '/lose' then check_game_existance
    when '/start' then start
    when '/game' then game
    when '/rules', '/statistics' then static_pages
    when '/hint' then hint
    when '/exit' then quit
    else Rack::Response.new(render('404'), 404)
    end
  end

  private

  def check_game_existance
    return show_page('menu') unless current_game

    return show_page('game') if current_game.attempts_total.positive?

    check_game_status
  end

  def check_game_status
    return show_page('lose') if current_game.guess_loss

    #Codebreaker::Storage.save(current_game)
    show_page('win')
  end

  def static_pages
    return show_page(@request.path) unless current_game

    check_game_existance
  end

  def start
    level = Difficulty.find(@request.params['level']).level

    @request.session[:game] = Codebreaker::Game.new(level)
    @request.session[:player] = @request.params['player_name']

    show_page('game')
  end

  def hint
    current_game.hint

    show_page('game')
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

  def t(phrase, *args)
    I18n.t(phrase, *args)
  end

  def show_page(template)
    Rack::Response.new(render(template))
  end

  def render(template)
    path = File.expand_path("../views/#{template}.html.erb", __FILE__)
    ERB.new(File.read(path)).result(binding)
  end
end
