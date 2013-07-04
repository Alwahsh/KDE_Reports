class AdminController < ApplicationController
  authorize_resource :class => false
  def index
    @users = User.all 
  end

  def control_user
    @user = User.find(params[:id])
    if params[:delete] != nil
      @user.remove_role(params[:role])
    else 
      @user.add_role(params[:role])
    end
    redirect_to root_url+"admin/"
  end
end
