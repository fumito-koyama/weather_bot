# WeatherBot

使い方
- slackでボットを作成し、チャンネルに招待
- slackの`Bot User OAuth Access Token`を取得し`SLACK_API_TOKEN`という環境変数にいれる
- `bot.rb`を起動してボットのいるチャンネルに`天気`と`都道府県名`が入る投稿をすると該当の都道府県の天気をボットが投稿する