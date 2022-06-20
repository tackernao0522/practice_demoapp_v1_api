require 'validator/email_validator'

class User < ApplicationRecord
  include TokenGenerateService # 追加 Token生成モジュール

  # Userクラスの一番上に追加
  # バリデーション直前
  before_validation :downcase_email

  # gem bcrypt
  # 1. passwordを暗号化する
  # 2. password_digest => password
  # 3. password_confirmation => パスワードの一致確認
  # 4. 一致のバリデーション追加
  # 5. authenticate()
  # 6. 最大文字数 72文字まで
  # 7. User.create() => 入力必須バリデーション、User.update() => x
  has_secure_password # 新規登録時はpassoword入力必須になる

  # validates
  # User.create(name: "                                        ")
  # 名前を入力してください。文字数は30文字まで(空白の場合には出ないようにする allow_blank: true)
  validates :name,
            presence: true,
            length: {
              maximum: 30,
              # Null(nil), 空白文字の場合スキップ(空白文字の場合には無駄な検証を行わない)
              # 入力必須
              # 最大文字数
              allow_blank: true
            }
  validates :email, presence: true, email: { allow_blank: true }

  VALID_PASSWORD_REGEX = /\A[\w\-]+\z/ # \z     => 文字列の末尾にマッチ
  validates :password,
            presence: true,
            length: {
              minimum: 8,
              # nameのみのupdate時にpasswordがnilになっていてもpassword必須とはならない(allow_nilが利く)
              # 最小文字数
              allow_blank: true
            },
            format: {
              # 書式チェック
              with: VALID_PASSWORD_REGEX,
              message: :invalid_password,
              allow_blank: true
            },
            # 空パスワードのアップデートを許容する。(Null(nil)の場合スキップ)
            allow_nil: true

  ## methods
  # class method  ###########################
  class << self
    def find_by_activated(email)
      find_by(email: email, activated: true)
    end
  end # class method end #########################

  # 自分以外の同じemailのアクティブなユーザーがいる場合にtrueを返す
  def email_activated?
    users = User.where.not(id: id)
    users.find_by_activated(email).present?
  end

  # リフレッシュトークンのJWT IDを記憶する
  def remember(jti)
    update!(refresh_jti: jti)
  end

  # リフレッシュトークンのJWT IDを削除する
  def forget
    update!(refresh_jti: nil)
  end

  # 共通のJSONレスポンス
  def response_json(payload = {})
    as_json(only: %i[id name]).merge(payload).with_indifferent_access
  end

  private

  # email小文字化
  def downcase_email
    self.email.downcase! if email
  end # emailからアクティブなユーザーを返す
end
