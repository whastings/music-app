# == Schema Information
#
# Table name: users
#
#  id               :integer          not null, primary key
#  email            :string(255)      not null
#  password_digest  :string(255)      not null
#  session_token    :string(255)      not null
#  created_at       :datetime
#  updated_at       :datetime
#  activated        :boolean          default(FALSE), not null
#  activation_token :string(255)
#  admin            :boolean          default(FALSE), not null
#

class User < ActiveRecord::Base
  validates :email, :password_digest, :session_token, presence: true
  validates :email, :session_token, uniqueness: true

  before_validation :check_token
  before_validation :check_activation_token

  has_many(
    :notes,
    primary_key: :id,
    foreign_key: :user_id,
    class_name: "Note",
    dependent: :destroy
  )

  def self.new_session_token
    SecureRandom.urlsafe_base64(16)
  end

  def self.find_by_credentials(email, password)
    user = self.find_by_email(email)
    (user && user.is_password?(password)) ? user : nil
  end

  def password=(password_string)
    self.password_digest = BCrypt::Password.create(password_string).to_s
  end

  def is_password?(password_string)
    BCrypt::Password.new(self.password_digest).is_password?(password_string)
  end

  def reset_session_token!
    self.session_token = self.class.new_session_token
    self.save!
    self.session_token
  end

  def activated?
    self.activated
  end

  def activate!
    self.activated = true
    self.save!
  end

  def admin?
    self.admin
  end

  def make_admin!
    self.admin = true
    self.save!
  end

  private

  def check_token
    self.session_token ||= self.class.new_session_token
  end

  def check_activation_token
    self.activation_token ||= SecureRandom.urlsafe_base64(10)
  end
end
