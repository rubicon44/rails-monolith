# 会員（会員集約のルート）
class Member < ApplicationRecord
  has_secure_password

  # 性別のエラーは、次の2つで役割を分けている
  #   ・不正な値（"other" など）：enum の validate が確認し、「性別は一覧にありません」を出す
  #   ・未選択（nil）：下の validates :gender, presence: true が確認し、「性別を選択してください」を出す
  # enum の validate は、そのままだと nil も不正な値として扱い、未選択でも「一覧にありません」を出してしまう
  # allow_nil: true で、nil の確認を presence に任せる
  enum :gender, { male: "male", female: "female" }, validate: { allow_nil: true }

  normalizes :email_address, with: -> email { email.strip.downcase }

  validates :name, presence: true, length: { maximum: 50 }
  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP, allow_blank: true }
  # パスワードだけでログインするため、最小15文字にする（README「パスワードの長さ」参照）
  validates :password, length: { minimum: 15 }, allow_nil: true
  validates :gender, presence: true
end
