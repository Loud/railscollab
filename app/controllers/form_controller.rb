=begin
RailsCollab
-----------

Copyright (C) 2007 James S Urquhart (jamesu at gmail.com)

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
=end

class FormController < ApplicationController

  layout 'project_website'
  
  verify :method => :post,
  		 :only => [ :delete ],
  		 :add_flash => { :flash_error => "Invalid request" },
         :redirect_to => { :controller => 'project' }

  before_filter :login_required
  before_filter :process_session
  before_filter :obtain_form, :except => [:index, :add]
  after_filter  :user_track, :only => [:index, :submit]
  
  def index
    if not ProjectForm.can_be_created_by(@logged_user, @active_project)
      flash[:flash_error] = "Insufficient permissions"
      redirect_back_or_default :controller => 'form'
      return
    end
    
    if @logged_user.member_of_owner?
  		@forms = @active_project.project_forms
    else
  		@forms = @active_project.visible_forms
  	end
  end
  
  def submit
    if not @form.can_be_submitted_by(@logged_user)
      flash[:flash_error] = "Insufficient permissions"
      redirect_back_or_default :controller => 'form'
      return
    end
    
    case request.method
      when :post
        form_attribs = params[:form]
        
        if @form.submit(form_attribs, @logged_user)
          ApplicationLog::new_log(@form, @logged_user, :add)
          flash[:flash_success] = @form.success_message
          redirect_back_or_default :controller => 'form'
        else
          flash[:flash_error] = "Error submitting form"
          redirect_back_or_default :controller => 'form'
        end
    end
    
    @visible_forms = @active_project.visible_forms
    @content_for_sidebar = 'submit_sidebar'
  end
  
  def add
    @form = ProjectForm.new
    
    if not ProjectForm.can_be_created_by(@logged_user, @active_project)
      flash[:flash_error] = "Insufficient permissions"
      redirect_back_or_default :controller => 'time'
      return
    end
    
    case request.method
      when :post
        form_attribs = params[:form]
        form_object_attribs = params[:form_objects]
                
        @form.attributes = form_attribs
        @form.attributes = form_object_attribs
        
        @form.project = @active_project
        @form.created_by = @logged_user
        
        if @form.save
          flash[:flash_success] = "Successfully added form"
          redirect_back_or_default :controller => 'form'
        end
    end
  end
  
  def edit
    if not @form.can_be_edited_by(@logged_user)
      flash[:flash_error] = "Insufficient permissions"
      redirect_back_or_default :controller => 'form'
      return
    end
    
    case request.method
      when :post
        form_attribs = params[:form]
        form_object_attribs = params[:form_objects]
        
        @form.attributes = form_attribs
        @form.attributes = form_object_attribs
        
        @form.project = @active_project
        @form.updated_by = @logged_user
        
        if @form.save
          flash[:flash_success] = "Successfully edited form"
          redirect_back_or_default :controller => 'form'
        end
    end
  end
  
  def delete
    if not @form.can_be_deleted_by(@logged_user)
      flash[:flash_error] = "Insufficient permissions"
      redirect_back_or_default :controller => 'form'
      return
    end
    
    @form.updated_by = @logged_user
    @form.destroy
    
    flash[:flash_success] = "Successfully deleted form"
    redirect_back_or_default :controller => 'form'
  end

private

  def obtain_form
    begin
      @form = ProjectForm.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      flash[:flash_error] = "Invalid form"
      redirect_back_or_default :controller => 'form'
      return false
    end
    
    return true
  end
end
