require 'bundler/setup'
Bundler.require
require 'sinatra/json'
require 'sinatra/reloader' if development?


post '/mokmoks/create' do
  challenge = {"challenge":"3eZbrw1aBm2rZgRNFdxV2595E9CY3gmdALWMmHkvFXO7tYXAYM8P"}
  json challenge
end

get '/mokmoks/create' do
  challenge = {"challenge":"3eZbrw1aBm2rZgRNFdxV2595E9CY3gmdALWMmHkvFXO7tYXAYM8P"}
  json challenge
end