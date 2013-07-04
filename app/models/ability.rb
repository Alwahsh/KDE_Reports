class Ability
  include CanCan::Ability

  def initialize(user)
    # Define abilities for the passed in user here. For example:
    #
    #   user ||= User.new # guest user (not logged in)
    #   if user.admin?
    #     can :manage, :all
    #   else
    #     can :read, :all
    #   end
    #
    # The first argument to `can` is the action you are giving the user 
    # permission to do.
    # If you pass :manage it will apply to every action. Other common actions
    # here are :read, :create, :update and :destroy.
    #
    # The second argument is the resource the user can perform the action on. 
    # If you pass :all it will apply to every resource. Otherwise pass a Ruby
    # class of the resource.
    #
    # The third argument is an optional hash of conditions to further filter the
    # objects.
    # For example, here the user can only update published articles.
    #
    #   can :update, Article, :published => true
    #
    # See the wiki for details:
    # https://github.com/ryanb/cancan/wiki/Defining-Abilities
    
    user ||= User.new # guest user (not logged in)
    
    alias_action :bugs_report, :to => :see_reports
    
    # An admin can do everything and can access the admin panel to give/take privileges.
    if user.has_role?(:admin)
      can :manage, :all
    else
      can :read, :all
      cannot [:index, :control_user], :admin
      can :see_reports, Project
    end
    # A super moderator can do everything as the admin except that he can't access the admin panel and can't give/take privileges.
    if user.has_role?(:super_moderator)
      can :manage, :all
      cannot [:index, :control_user], :admin
    end
    # A super developer can do anything in the Project model only.
    if user.has_role?(:super_developer)
      can :manage, Project
    end
    # A super editor can do anything in the News model only.
    if user.has_role?(:super_editor)
      can :manage, News
    end
    # A developer can add new projects and can edit and delete his projects only.
    if user.has_role?(:developer)
      can :manage, Project do |pr|
          pr.users.include?(user)
      end
      can [:new, :create], Project
    end    
    # An editor can add new news and can edit and delete his news only.
    if user.has_role?(:editor)
      can :manage, News , :user_id => user.id
    end
  end
end
