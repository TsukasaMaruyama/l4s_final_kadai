require 'bundler/setup'
Bundler.require
require 'sinatra/json'
require 'sinatra/reloader' if development?
require "./models"
require "date"
require 'bcrypt'
enable :sessions
require "pry"
require "uri"
require "./models"

SLACK＿API_BASE = "https://slack.com/api/";

# アプリ固有のトークン
# レガシートークンは使わない
BOT_TOKEN = "xoxb-448569467826-451046062055-MpcbpQlJa9ZD1qaQPmMJ0KYd"
OAUTH_TOKEN = "xoxp-448569467826-448569468674-451339389814-4ccc14ef139917905119c5f82cd21556"
CLIENT_ID = "448569467826.449373732897"
CLIENT_SECRET = "8d92c2a03da08e089138da5340f8845c"

# レガシートークン使いたくない
WORKSPACE_TOKEN = "xoxp-448569467826-448569468674-450685271188-8c0fccbb4a1cf6b51daa69f3accc4386"

before do
	unless 
		request.path.include?('/signin') ||
		request.path.include?('/create_mokmok') || 
		request.path.include?('/event_catch_json') ||
		request.path.include?('/event_catch_post') ||
		request.path.include?('/signin_with_slack')
		
		unless session[:user].nil?
			@current_user = session[:user]
    else
    	redirect "/signin"
    end  	
  end
end

def openDialog(dialog, trigger_id)
	res = Net::HTTP.post_form(URI.parse("https://slack.com/api/dialog.open?token=#{OAUTH_TOKEN}&dialog=#{dialog.to_json}&trigger_id=#{trigger_id}&pretty=1"),{trigger_id: trigger_id, dialog: dialog.to_json, token: OAUTH_TOKEN})
	return res
end

def exportMemberIds(oauth_token,channel)
	url = SLACK＿API_BASE + "channels.info?token=" + oauth_token + "&channel=" + channel + "&pretty=1"
	res = Net::HTTP.get(URI.parse(url))
	res = JSON.parse(res)
	return res['channel']['members']
end

def exportMemberInfo(oauth_token,member_id)
	url = SLACK＿API_BASE + "users.info?token=" + oauth_token + "&user=" + member_id + "&pretty=1"
	res = Net::HTTP.get(URI.parse(url))
	res = JSON.parse(res)["user"]
	return res
end

def exportAllChannelNames(oauth_token)
	channels = exportChannelList(oauth_token)
	names = {}
	talk({text: channels.to_json})
	channels.each {|channel|
		names[channel["id"]] = channel["name"]
	}
	return names;
end

def exportMemberName(oauth_token, member_id)
	res = exportMemberInfo(oauth_token, member_id)
	return res["profile"]["real_name"]
end

def exportChannelList(oauth_token)
	url = "https://slack.com/api/channels.list?token=#{oauth_token}&pretty=1"
	res = JSON.parse(Net::HTTP.get(URI.parse(url)))
	return res["channels"]
end

post '/create_mokmok' do
	trigger_id = params[:trigger_id]
	dates = []
	today = Date.today
	(0..30).each{ |num|
		dates << {label: today + num, value: today + num}
	}
	times = []
	(0..47).each{ |num|
		time = "#{num/2}:"
		if num % 2 == 1
			time = time + "30"
		else
			time = time + "00"
		end
		times << {label: time, value: time}
	}
	talk({text: dates.to_json})
	dialog =
	{
		callback_id: "new_mokmok",
		title: "New MokMok",
		submit_label: "Request",
		state: "Limo",
		elements: [
			{
				label: "Title",
				name: "title",
				type: "text",
				subtype: "email",
				placeholder: "WEBS MokMok"
				
			},
			{
				label: "Place",
				name: "place",
				type: "text",
				placeholder: "sibuya"
				
			},
			{
				label: "Date",
				type: "select",
				name: "date",
				options: dates
			},
			{
				label: "Start Time",
				type: "select",
				name: "start_time",
				options: times
				
			},
			{
				label: "Finish Time",
				type: "select",
				name: "finish_time",
				options: times
			},
		]
	}
	res = openDialog(dialog,trigger_id)
	talk({text: trigger_id})
	talk({text: "res"+res.body})
	return
end

def talk(content)
	talkWithWebhook(content,"https://hooks.slack.com/services/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")
end

# イベントサブスクリプションのイベント
# https://api.slack.com/apps/AD4E4GT8B/event-subscriptions?
post '/event_catch_json' do
	json_data = JSON.parse(request.body.read)

	if json_data["challenge"]
		res = {challenge: json_data["challenge"]}
	end

	if json_data["event"]
		event_type = json_data["event"]["type"]
	end

	if event_type == "app_mention"
		if true || json_data["event"]["text"].include?("もくもく会") && json_data["event"]["text"].include?("作")
			talk({text: "hello"})
		end
	end
	json res
end

# もくもく会作成押した時
# もくもく会参加ボタン押した時
# インタラクティブコンポーネントのイベント
# https://api.slack.com/apps/AD4E4GT8B/interactive-messages?
# ボタンなど押した時に最初に呼ばれるところ
post '/event_catch_post' do
	talk({text: "this is event catch post"})
	payload = JSON.parse(params["payload"])
	
	type = payload["type"]
	# talk({text: params["payload"]})
	# ボタンが押された時
	if type == "interactive_message"
		if payload["callback_id"] == "participate_mokmok"
			participateMokmok(payload)
		end
		
	# dialogが送られた時
	elsif type == "dialog_submission"
		if payload["callback_id"] == "new_mokmok"
			createNewMokmok(payload)
		end
	end


	return
end

def createNewMokmok(payload)
	
	team_id = payload["team"]["id"]
	channel_id = payload["channel"]["id"]
	user_id = payload["user"]["id"]
	title = payload["submission"]["title"]
	date = payload["submission"]["date"]
	place = payload["submission"]["place"]
	# talk({"text": date + "T" + payload["submission"]["start_time"]})
	start_date = DateTime.parse(date + "T" + payload["submission"]["start_time"])
	finish_date = DateTime.parse(date + "T" + payload["submission"]["finish_time"])
	
	# dbにほぞんする
	mokmok = Mokmok.create(
		title: title,
		start_date: start_date,
		finish_date: finish_date,
		creator_id: user_id,
		channel_id: channel_id,
		team_id: team_id,
		place: place
	)
	
	# channelにもくもく会できました&参加ボタン付きメッセを送る
	
	participate_btn =
	{
		text: "もくもく会が作成されました",
		attachments: 
		[
				{
						fallback: "You are unable to choose a game",
						callback_id: "participate_mokmok",
						color: "#3AA3E3",
						attachment_type: "default",
						title: title,
						text: "#{start_date.strftime("%m/%d %H:%M")}~#{finish_date.strftime("%H:%M")} in #{place}" ,
						actions: [
								{
										name: "participate",
										text: "参加する",
										type: "button",
										value: mokmok.id
								},
						]
				},
				{
					title: "詳細URL",
					text: "https://mokmok-aldytsukasa.c9users.io/mokmoks/#{mokmok.id}"
				}
		]
	}

	talk(participate_btn)
end

def participateMokmok(payload)
	# mokmok_id user_id comment
	mokmok_id = payload["actions"][0]["value"]
	user_id = payload["user"]["id"]
	if ParticipateUser.find_by(user_id: user_id, mokmok_id: mokmok_id).nil?
		ParticipateUser.create(
			mokmok_id: mokmok_id,
			user_id: user_id
		)
	end
	mokmok = Mokmok.find(mokmok_id)
	user_name = exportMemberName(OAUTH_TOKEN, user_id)
	# talk({text: user_name})
	res = talkWithChannelId({text: "【#{mokmok.title} @#{mokmok.place}】に#{user_name}さんが参加しました\n詳細:https://mokmok-aldytsukasa.c9users.io/mokmoks/detail/#{mokmok.id}", channel: mokmok.channel_id, token: BOT_TOKEN})
end

def talkWithWebhook(content, webhook)
	uri = URI.parse(webhook)
	https = Net::HTTP.new(uri.host, uri.port)
	https.use_ssl = true # HTTPSでよろしく
	req = Net::HTTP::Post.new(uri.request_uri)
	req["Content-Type"] = "application/json" # httpリクエストヘッダの追加
	payload = content.to_json
	req.body = payload # リクエストボデーにJSONをセット
	https.request(req)
end

# https://api.slack.com/methods/chat.postMessage
def talkWithChannelId(content)
	text = URI.encode(content[:text])
	url = "https://slack.com/api/chat.postMessage?token=#{BOT_TOKEN}&channel=#{content[:channel]}&text=#{text}&pretty=1"
	res = Net::HTTP.get(URI.parse(url))
	return res
end

get '/' do
	@mokmoks = Mokmok.all
	erb :index
end

get '/mokmoks/view/:id' do
	@mokmok = Mokmok.find(params[:id])
	erb :mokmok_ditail
end

get '/mokmoks' do
	talk({text: session[:team].to_json})
	team_id = session[:team]["id"]
	@mokmoks_created = Mokmok.where("team_id = ? AND creator_id = ?",team_id, session[:user]["id"])
	
	@mokmoks = Mokmok.where("team_id = ? AND channel_id IN (?)", team_id, session[:channels])
	@creators = {}
	@participate_users = {}
	@mokmoks.each{|mokmok|
			@creators[mokmok.id] = exportMemberInfo(WORKSPACE_TOKEN, mokmok.creator_id)["profile"]
			mokmok.participate_users.each {|participate_user|
				@participate_users[mokmok.id] = {}
				@participate_users [mokmok.id][participate_user.user_id] =  exportMemberInfo(WORKSPACE_TOKEN, participate_user.user_id)["profile"]
			}
	}
	@channels = exportAllChannelNames(BOT_TOKEN)
	talk({text: @creators.to_json})
	erb :mokmoks
end

get '/signin' do
	erb :signin
end

get '/signin_with_slack' do
	talk({text: params[:code]})
	url = "https://slack.com/api/oauth.access?client_id=#{CLIENT_ID}&client_secret=#{CLIENT_SECRET}&code=#{params[:code]}"
	res = Net::HTTP.get(URI.parse(url))
	data = JSON.parse(res)
	# talk({text: res})
	data = exportUserInfoWithAccessToken(data["access_token"])
	data = symbolize_keys(data)
	session[:user] = data[:user]
	session[:team] = data[:team]
	session[:channels] = getJoinedChannelIds(session[:user]["id"])
	# talk({text: "this is use info " + session[:channels]})
	redirect '/mokmoks'
end

def exportUserInfoWithAccessToken(access_token)
	url = "https://slack.com/api/users.identity?token=#{access_token}"
	res = Net::HTTP.get(URI.parse(url))
	return JSON.parse(res)
end

def getJoinedChannelIds(member_id) 
	url = "https://slack.com/api/channels.list?token=#{BOT_TOKEN}&pretty=1"
	res = JSON.parse(Net::HTTP.get(URI.parse(url)))
	channels = res["channels"]
	talk({text: channels.to_json})
	channel_ids = []
	channels.each{|channel| 
		member_ids = channel["members"]
		if member_ids.include?(member_id)
			channel_ids << channel["id"]
		end
	}
	return channel_ids
end

def symbolize_keys(hash)
  hash.map{|k,v| [k.to_sym, v] }.to_h
end