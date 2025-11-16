# frozen_string_literal: true

RailsImagePostSolution.configure do |config|
  # OpenAI APIキー（環境変数から取得することを推奨）
  config.openai_api_key = ENV["OPENAI_API_KEY"]

  # 不適切なコンテンツが検出された際に自動で投稿を凍結するか
  # デフォルト: true
  config.auto_freeze_on_flag = true

  # 管理者権限チェックのメソッド名
  # current_userに対して呼び出されるメソッド名を指定
  # デフォルト: :admin?
  config.admin_check_method = :admin?
end
