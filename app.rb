require 'bundler/setup'
Bundler.require
require 'sinatra/json'
require 'sinatra/reloader' if development?

require 'net/http'
require 'uri'

SLACK＿API_BASE = "https://slack.com/api/";
WORKSPACE_TOKEN = "xoxp-448569467826-448569468674-448060794785-8d27c6b6a6c815eaa066a0c20fb26ad5"

def httpsPost(url, body)
  uri = URI.parse(url)

response = nil

request = Net::HTTP::Post.new(uri.request_uri, initheader = {'Content-Type' =>'application/json'})
request.body = body.to_json

http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true
http.verify_mode = OpenSSL::SSL::VERIFY_NONE

http.set_debug_output $stderr

http.start do |h|
  response = h.request(request)
end
end

def openDialog(dialog, trigger_id)
  httpsPost('https://slack.com/api/dialog.open', {'dialog' => dialog.to_json, 'trigger_id' => trigger_id})
  return res.body
end

def exportMemberIds(workspace_token,channel)
  url = SLACK＿API_BASE + "channels.info?token=" + workspace_token + "&channel=" + channel + "&pretty=1"
  res = Net::HTTP.get(URI.parse(url))
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
  return res["profile"]["real_name"]
end

post '/create_mokmok' do
trigger_id = params[:trigger_id]
dialog =
{
  "callback_id": "ryde-46e2b0",
  "title": "Request a Ride",
  "submit_label": "Request",
  "state": "Limo",
  "elements": [
    {
      "type": "text",
      "label": "Pickup Location",
      "name": "loc_origin"
    },
    {
      "type": "text",
      "label": "Dropoff Location",
      "name": "loc_destination"
    }
  ]
}

res = openDialog(dialog,trigger_id)
talk({"text": trigger_id})
talk({"text": "res"+res})
return
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
  # talk({"text": params["payload"]})

  talk({"text": params["payload"]})
  user_name = exportMemberName(WORKSPACE_TOKEN, payload["user"]["id"])
  talk({"text": user_name + "さんが参加します"})

  return
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
