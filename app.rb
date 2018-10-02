require 'bundler/setup'
Bundler.require
require 'sinatra/json'
require 'sinatra/reloader' if development?

require 'net/http'
require 'uri'

SLACK＿API_BASE = "https://slack.com/api/";
WORKSPACE_TOKEN = "xoxp-414625309937-415718066981-447003139841-5f842f459142c99a295a7cdb1d87ac2e"

def exportMemberIds(workspace_token,channel)
  url = SLACK＿API_BASE + "channels.info?token=" + workspace_token + "&channel=" + channel + "&pretty=1"
  res = Net::HTTP.get_print(URI.parse(url))
  res = JSON.parse(res)
  return res['channel']['members']
end

def exportMemberInfo(workspace_token,member_id)
  url = SLACK＿API_BASE + "users.info?token=" + workspace_token + "&user=" + member_id + "&pretty=1"
  res1 = Net::HTTP.get_print(URI.parse(url))
  res = JSON.parse(res1)
  return res['user']
end

post '/mokmoks/create' do
  params = JSON.parse request.body.read
  res = {challenge: params["challenge"]}
  user_info = exportMemberInfo(WORKSPACE_TOKEN, params['event']['user'])
  user_name = user_info["name"]
  talk({"text": user_name})
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
  data = params["payload"]
  talk({"text": params["payload"]})
  json params
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
