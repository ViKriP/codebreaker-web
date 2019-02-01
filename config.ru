# frozen_string_literal: true

require_relative 'autoloader.rb'

use Rack::Reloader
use Rack::Static, urls: ['/assets', '/node_modules'], root: './'
use Rack::Session::Cookie, key: 'rack.session', path: '/', secret: 'secret'

run Racker
