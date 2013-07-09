class AdminUser < ActiveRecord::Base
    # Include default devise modules. Others available are:
    # :token_authenticatable, :confirmable,
    # :lockable, :timeoutable and :omniauthable
    devise :database_authenticatable, 
            :recoverable, :rememberable, :trackable, :validatable, :registerable

    # Setup accessible (or protected) attributes for your model
    attr_accessible :email, :password, :password_confirmation, :remember_me, :manager, :group_id, :state_event

    # attr_accessible :title, :body
    
    before_save :create_active_token
    
    scope :inactive, where("admin_users.state = 'inactive'")
    scope :active, where("admin_users.state = 'active'")
    
    validates :group_id, presence: true, on: :update
    
    validate :forbid_changing_email, on: :update
    
    state_machine :state, :initial => :inactive do
        after_transition :inactive => :active do |user, transition|
            UserMailer.activated(user).deliver
        end
        
        event :activate do
            transition :inactive => :active
        end
        
        event :deactivate do
            transition :active => :inactive
        end
        
        state :inactive, :value => 'inactive'
        state :active, :value => 'active'
    end
    
    def active_for_authentication?
        super && self.active?
    end
    
    def group
        if self.group_id == nil
            nil
        else
            Group.find_by_id(self.group_id)
        end
    end
    
    def group=(group)
        self.group_id = group.id
    end
    
    def admin?
       if self.group != nil
           self.group.admin?
       else
           false
       end
    end
    
    def self.admins
        AdminUser.find_by_sql("SELECT admin_users.* FROM admin_users INNER JOIN groups ON admin_users.group_id = groups.id WHERE groups.admin = 't'")
    end
    
    def self.admin_emails
        emails = Array.new
        
        self.admins.each do |admin|
            emails.push admin.email
        end
        
        emails
    end
    
    # These are used to track email changes
#     def email
#         @email
#     end
#     
#     def email=(value)
#         attribute_will_change!('email') if email != value
#         @email = value
#     end
#     
#     def email_changed?
#         changed.include?('email')
#     end
    
    def forbid_changing_email
        errors[:name] = "can not be changed!" if self.email_changed?
    end
    
    private
        def create_active_token
            self.active_token = SecureRandom.urlsafe_base64
        end
end

# == Schema Information
#
# Table name: admin_users
#
#  id                     :integer         not null, primary key
#  email                  :string(255)     default(""), not null
#  encrypted_password     :string(255)     default(""), not null
#  reset_password_token   :string(255)
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  sign_in_count          :integer         default(0)
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :string(255)
#  last_sign_in_ip        :string(255)
#  created_at             :datetime        not null
#  updated_at             :datetime        not null
#  state                  :string(255)
#  manager                :boolean
#  active_token           :string(255)
#  active_token_sent_at   :datetime
#  group_id               :integer
#

