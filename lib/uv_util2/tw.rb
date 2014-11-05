require "twitter"
require "oauth"

module UvUtil2
  class Tw
    def initialize(twitter_key, twitter_secret, callback)
      @twitter_key = twitter_key
      @twitter_secret = twitter_secret
      @callback = callback
    end

    # OAuthコンシューマー取得
    def get_oauth_consumer
      OAuth::Consumer.new(
        @twitter_key,
        @twitter_secret,
        :site => "https://api.twitter.com"
      )
    end

    # 最初のリクエストトークン取得
    def get_first_request_token
      oauth_consumer = get_oauth_consumer
      oauth_consumer.get_request_token(
        oauth_callback: @callback
      )
    end
  
    # リクエストトークン取得
    def get_request_token(request_token, request_token_secret)
      OAuth::RequestToken.new(
        get_oauth_consumer, 
        request_token, 
        request_token_secret
      )
    end
  
    # Twitterクライアント取得
    def get_twitter_client(access_token, access_token_secret)
      Twitter::REST::Client.new do |config|
        config.consumer_key        = @twitter_key
        config.consumer_secret     = @twitter_secret
        config.access_token        = access_token
        config.access_token_secret = access_token_secret
      end
    end

    # Twitterクライアントをスレッド毎に保持
    # ループ毎のTwitterクライアントのインスタンス化を防ぐ
    def get_client_thread(key_code, secret_code, key: :twitter_client)
      client = Thread.current[key] ||= 
        get_twitter_client("", "")
      client.access_token = key_code
      client.access_token_secret = secret_code
      client
    end
  end
end
