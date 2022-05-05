class User < ApplicationRecord
  has_secure_password

  validates :name, presence: true,
            length: {
              maxmum: 30,
              allow_blank: true
            }

  VALID_PASSWORD_REGEX = /\A[\w\-]+\z/

  validates :password, presence: true,
            length: {
              minimum: 8,
              allow_blank: true
            },
            format: {
              with: VALID_PASSWORD_REGEX,
              allow_blank: true
            },
            allow_nil: true
end
