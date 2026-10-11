class Administrator < ApplicationRecord
  has_secure_password

  normalizes :email_address, with: -> email { email.strip.downcase }

  validates :name, presence: true
  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP, allow_blank: true }
end
