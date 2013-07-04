class AddBugsReportFieldsToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :bugs_report_fields, :text
  end
end
