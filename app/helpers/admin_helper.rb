module AdminHelper
  def render_links role,user
    render :partial => "role_management_links", :locals => { :role => role, :user => user }
  end
end
