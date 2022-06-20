class ApplicationController < ActionController::API
  # Cookieを扱う
  include ActionController::Cookies
  # 認可を行う
  include UserAuthenticateService
  # CSRF対策
  before_action :xhr_request?

  private

  # SMLHttpRequest出ない場合は403エラーを返す
  def xhr_request?
    return if request.xhr?
    render status: :forbidden, json: { status: 403, error: 'Forbidden' }
  end

  # Internal Server Error
  def response_500(msg = 'Internal Server Error')
    # リクエストヘッダ C=Requested-With: 'XMLHttpRequest'の存在を判定
    render status: 500, json: { status: 500, error: msg }
  end
end
