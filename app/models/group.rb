# == Schema Information
#
# Table name: groups
#
#  id         :integer         not null, primary key
#  name       :string(255)
#  created_at :datetime        not null
#  updated_at :datetime        not null
#  admin      :boolean
#

class Group < ActiveRecord::Base
  attr_accessible :name
  validates :name, presence: true, uniqueness: { case_sensitive: false }
  has_many :admin_users
  
  def managers
    admin_users.find_by_sql("SELECT * FROM admin_users WHERE manager = 't'")
  end
end
