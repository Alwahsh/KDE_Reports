class HomeController < ApplicationController
  def index
    @news = News.first(:order => 'id DESC')
    @projects = Project.find(:all, :order => "id desc", :limit => 5)
  end
end
