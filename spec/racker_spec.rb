# frozen_string_literal: true

RSpec.describe Racker do
  let(:app) { Rack::Builder.parse_file('config.ru').first }
  let(:game) { Codebreaker::Game.new(Difficulty.find('easy').level) }
  let(:test_db_path) { './lib/db/test_db.yml' }

  before do
    stub_const('Codebreaker::Storage::STATS_DB', test_db_path)
    File.open(Codebreaker::Storage::STATS_DB, 'w') { |file| file.write(YAML.dump([])) }
  end

  after do
    File.delete(test_db_path)
  end

  describe 'statuses' do
    context 'when root path' do
      before { get '/' }

      it 'returns status ok' do
        expect(last_response).to be_ok
      end

      it { expect(last_response.body).to include I18n.t(:short_rules) }
    end

    context 'when rules path' do
      before { get '/rules' }

      it { expect(last_response).to be_ok }
      it { expect(last_response.body).to include I18n.t(:rules) }
    end

    context 'when unknown routes' do
      before { get '/unknown' }

      it { expect(last_response).to be_not_found }
      it { expect(last_response.body).to include I18n.t(:not_found) }
    end
  end

  describe '#start' do
    before do
      post '/start', level: game.difficulty_name
    end

    context 'creates Game instance in session' do
      it { expect(last_request.session[:game]).not_to be nil }
      it { expect(last_request.session[:game].difficulty_name).to eq game.difficulty_name }
    end

    context 'responses with game page' do
      it 'responses with ok status' do
        expect(last_response).to be_ok
      end
    end
  end

  describe '#game' do
    before do
      env 'rack.session', game: game, player: 'Player1'
      get '/'
    end

    it 'makes check mark in session' do
      post '/game', number: '1234'
      expect(last_response.body).to include I18n.t(:marks_answer)
    end

    it 'redirects to win page in game won case' do
      post '/game', number: last_request.session[:game].secret_code.join
      expect(last_response.body).to include I18n.t(:congratulations)
    end

    context '' do
      before do
        game.attempts = 0
        env 'rack.session', game: game, player: 'Player1'
      end

      it 'redirects to lose page in game lost case' do
        post '/game', number: '1234'
        expect(last_response.body).to include I18n.t(:oops)
      end
    end
  end

  describe '#hint' do
    context "when doesn't session player" do
      before do
        env 'rack.session', game: game
      end

      it do
        post '/hint'
        expect(last_response.body).to include I18n.t(:short_rules)
      end
    end

    context 'when answer hint' do
      before do
        game.user_hints = [1, 1, 1, 1]
        env 'rack.session', game: game, player: 'Player1'
      end

      it do
        post '/hint'
        expect(last_response.body).to include I18n.t(:show_hint)
      end
    end
  end

  describe '#stats' do
    it do
      post '/statistics'
      expect(last_response.body).to include I18n.t(:top_player)
    end
  end
end
