require 'bundler/setup'
Bundler.require
require 'sinatra/json'
require 'sinatra/reloader' if development?

require 'net/http'
require 'uri'

SLACK＿API_BASE = "https://slack.com/api/";
WORKSPACE_TOKEN = "xoxp-448569467826-448569468674-448758242373-a69df99a15f43fca50947422635deba4"

def exportMemberIds(workspace_token,channel)
  url = SLACK＿API_BASE + "channels.info?token=" + workspace_token + "&channel=" + channel + "&pretty=1"
  res = Net::HTTP.get_print(URI.parse(url))
  res = JSON.parse(res)
  return res['channel']['members']
end

def exportMemberInfo(workspace_token,member_id)
  url = SLACK＿API_BASE + "users.info?token=" + workspace_token + "&user=" + member_id + "&pretty=1"
  res = Net::HTTP.get(URI.parse(url))
  res = JSON.parse(res)["user"]
  return res
end

def exportMemberName(workspace_token, member_id)
  res = exportMemberInfo(workspace_token, member_id)
  return res["profile"]["display_name"]
end

def postMokMok()
  content =
  {
    "text": "Would you like to play a game?",
    "attachments": [
        {
            "text": "Choose a game to play",
            "fallback": "You are unable to choose a game",
            "callback_id": "wopr_game",
            "color": "#3AA3E3",
            "attachment_type": "default",
            "actions": [
                {
                    "name": "game",
                    "text": "Chess",
                    "type": "button",
                    "value": "chess"
                },
                {
                    "name": "game",
                    "text": "Falken's Maze",
                    "type": "button",
                    "value": "maze"
                },
                {
                    "name": "game",
                    "text": "Thermonuclear War",
                    "style": "danger",
                    "type": "button",
                    "value": "war",
                    "confirm": {
                        "title": "Are you sure?",
                        "text": "Wouldn't you prefer a good game of chess?",
                        "ok_text": "Yes",
                        "dismiss_text": "No"
                    }
                }
            ]
        }
    ]
}
  talk(content)
end

post '/mokmoks/create' do
  params = JSON.parse request.body.read
  res = {challenge: params["challenge"]}
  user_info = exportMemberInfo(WORKSPACE_TOKEN, params['event']['user'])
  user_name = user_info["profile"]["display_name"]
  text = params["event"]["text"]
  talk({"text": params["challenge"]})
  talk({"text": "Hello! " + user_name + " " + text})
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

# イベントサブスクリプションのイベント
# https://api.slack.com/apps/AD4E4GT8B/event-subscriptions?
post '/event_catch_json' do
  json_data = JSON.parse(request.body.read)

  if json_data["challenge"]
    res = {"challenge": json_data["challenge"]}
  end

  if json_data["event"]
    event_type = json_data["event"]["type"]
  end

  if event_type == "app_mention"
    if true || json_data["event"]["text"].include?("もくもく会") && json_data["event"]["text"].include?("作")
      postMokMok()
    end
  end
  json res
end

# インタラクティブコンポーネントのイベント
# https://api.slack.com/apps/AD4E4GT8B/interactive-messages?
# ボタンなど押した時に最初に呼ばれるところ
post '/event_catch_post' do
  payload = JSON.parse(params["payload"])
  #  user_name= params["challenge"]
  user_name = exportMemberName(WORKSPACE_TOKEN, payload["user"]["id"])
  # talk({"text": user_name})
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
