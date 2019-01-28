# frozen_string_literal: true

require_relative 'autoloader.rb'

use Rack::Reloader
use Rack::Session::Cookie, key: 'rack.session', path: '/', secret: 'secret'
use Rack::Static, urls: ['/assets'], root: 'public'

run Racker
