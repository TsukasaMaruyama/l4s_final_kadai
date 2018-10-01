require 'bundler/setup'
Bundler.require
require 'sinatra/json'
require 'sinatra/reloader' if development?

require 'net/http'
require 'uri'


post '/mokmoks/create' do
  params = JSON.parse request.body.read
  res = {challenge: params["challenge"]}
  json res
end

def talk(content)
  uri = URI.parse("https://hooks.slack.com/services/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")
  https = Net::HTTP.new(uri.host, uri.port)
  https.use_ssl = true # HTTPSでよろしく
  req = Net::HTTP::Post.new(uri.request_uri)

  req["Content-Type"] = "application/json" # httpリクエストヘッダの追加
  payload = content.to_json
  req.body = payload # リクエストボデーにJSONをセット
  https.request(req)
end

post '/event_catch' do
  talk({text: "イベントをキャッチしました"+params[:mokmok]})
end

get '/mokmoks/create' do
  content = {
    "text": "もくもく会に参加しますか?",
    "attachments": [
      {
        "fallback": "You are unable to choose a game",
        "callback_id": "participate_mokmok",
        "color": "#3AA3E3",
        "attachment_type": "default",
        "actions": [
          {
            "name": "mokmok",
            "text": "参加する",
            "type": "button",
            "value": "true"
          },
          {
            "name": "mokmok",
            "text": "参加しない",
            "type": "button",
            "value": "false"
          }
        ]
      }
    ]
  }
  talk(content)
  challenge = {challenge:"3eZbrw1aBm2rZgRNFdxV2595E9CY3gmdALWMmHkvFXO7tYXAYM8P"}
  json challenge
end
