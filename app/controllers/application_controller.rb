class ApplicationController < ActionController::API
  # Cookieを扱う
  include ActionController::Cookies
  # 認可を行う
  include UserAuthenticateService
end
