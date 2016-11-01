class User < ActiveRecord::Base
  has_many :orders
  has_many :products
  has_many :reviews
  has_many :orderitems

  validates :uid, :provider, presence: true

  validates :username, presence: true, uniqueness: true
  validates :email, presence: true, uniqueness: true, format: {with: /@/}

  def self.log_in(username, password)
    somebody = self.find_by(username: username)
    somebody && somebody.authenticate(password)
  end

  def revenue
    Orderitem.where(user: self.id).sum(:price)
  end

  def revenue_by_status(status)
    Orderitem.joins(:order).where("orderitems.user_id = ? and orders.status = ?", self.id, status).sum(:price)
  end

  def order_by_status(status)
    Orderitem.joins(:order).where("orderitems.user_id = ? and orders.status = ?", self.id, status).uniq.pluck(:order_id).count
  end

  OAUTH_PROVIDERS = [:developer]

  def self.find_or_create_by_auth_hash(provider, auth_hash)
    return nil unless OAUTH_PROVIDERS.include? provider

    # Find a user with the given UID and provider
    find_or_create_by({
      uid: auth_hash['uid'],
      provider: provider
    }) do |user|
      # If it's not found, create a new one with that UID and provider
      # and use the appropriate method to configure the other attributes
      self.send :"create_by_#{provider}", user, auth_hash
    end
  end

  private

  def self.create_by_developer(user, auth_hash)
    user.username = auth_hash['info']['name']
    user.full_name = auth_hash['info']['name']
    user.email = auth_hash['info']['email']
  end
end
