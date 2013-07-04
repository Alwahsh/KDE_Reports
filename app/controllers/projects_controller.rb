class ProjectsController < ApplicationController
  
  # Add authorization using cancan.
  load_and_authorize_resource
  # GET /projects
  # GET /projects.json
  def index
    @projects = Project.roots

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @projects }
    end
  end

  # GET /projects/1
  # GET /projects/1.json
  def show
    @project = Project.find(params[:id])
    @projects = @project.children
    respond_to do |format|
      if @projects.empty?
        # Requesting a project that has no sub projects gives its info.
        format.html # show.html.erb
        format.json { render json: @project }
      else 
        # Requesting a project that has sub projects gives a list of all of its sub projects. 
        format.html { render "index" } # index.html.erb
        format.json { render json: @projects }
      end
    end
  end

  # GET /projects/new
  # GET /projects/new.json
  def new
    @project = Project.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @project }
    end
  end

  # GET /projects/1/edit
  def edit
    @project = Project.find(params[:id])
  end

  # POST /projects
  # POST /projects.json
  def create
    params[:project][:bugs_report_fields] ||= []  
    @project = Project.new(params[:project])
    @project.users << current_user
    respond_to do |format|
      if @project.save
        format.html { redirect_to @project, notice: 'Project was successfully created.' }
        format.json { render json: @project, status: :created, location: @project }
      else
        format.html { render action: "new" }
        format.json { render json: @project.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /projects/1
  # PUT /projects/1.json
  def update
    params[:project][:bugs_report_fields] ||= []  
    @project = Project.find(params[:id])

    respond_to do |format|
      if @project.update_attributes(params[:project])
        format.html { redirect_to @project, notice: 'Project was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @project.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /projects/1
  # DELETE /projects/1.json
  def destroy
    @project = Project.find(params[:id])
    @project.destroy

    respond_to do |format|
      format.html { redirect_to projects_url }
      format.json { head :no_content }
    end
  end
  
  # GET /projects/1/bugs_report
  # GET /projects/1/bugs_report.json
  def bugs_report
    @project = Project.find(params[:id])
    @data = @project.get_bugs_report
    
    respond_to do |format|
      format.html #bugs_report.html.erb
      format.json 
    end
  end
  
  def bugs_list
    @project = Project.find(params[:id])
    @number_of_bugs = Array.new(@project.number_of_bugs,nil)
    @number_of_pages = @number_of_bugs.paginate(:page => params[:page] ,:per_page => params[:view] ||= 10 )
    @bugs = @project.list_of_bugs(params[:page],params[:view].to_i ||= 10)
    respond_to do |format|
      format.html # bugs_list.html.erb
      format.json { render json: @bugs }
    end
  end
  
end
