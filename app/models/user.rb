class User < ActiveRecord::Base
  rolify
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :username, :email, :password, :password_confirmation, :message, :remember_me
  # attr_accessible :title, :body
  
  # Adding a many to many relationship between projects and users.
  has_and_belongs_to_many :projects
  
  # Adding a one to many relationship between users and news.
  has_many :news
  
  # Add a "undecided" role to all new users.
  after_create :assign_undecided_role
  private
  def assign_undecided_role
    self.add_role "undecided"
  end
  
end
