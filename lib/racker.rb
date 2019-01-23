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
    else Rack::Response.new(render('404'), 404)
    end
  end

  private

  def check_game_existance
    return show_page('menu') unless current_game
  end

  def static_pages
    return show_page(@request.path) unless current_game

    check_game_existance
  end

  def current_game
    @request.session[:game]
  end

  def session_param_nil?(param)
    @request.session[param].nil?
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
