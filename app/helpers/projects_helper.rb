# encoding: utf-8
#
# Redmine - project management software
# Copyright (C) 2006-2011  Created by  DomThual & SPecchiaSoft (2013) 
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

module ProjectsHelper
  def link_to_version(version, options = {})
    return '' unless version && version.is_a?(Version)
    link_to_if version.visible?, format_version_name(version), { :controller => 'versions', :action => 'show', :id => version }, options
  end

  def project_settings_tabs
    tabs = [{:name => 'info', :action => :edit_project, :partial => 'projects/edit', :label => :label_settings},
            {:name => 'modules', :action => :select_project_modules, :partial => 'projects/settings/modules', :label => :label_module_plural},
            {:name => 'members', :action => :manage_members, :partial => 'projects/settings/members', :label => :label_member_plural},
            {:name => 'versions', :action => :manage_versions, :partial => 'projects/settings/versions', :label => :label_version_plural},
            {:name => 'categories', :action => :manage_categories, :partial => 'projects/settings/issue_categories', :label => :label_issue_category_plural},
            {:name => 'wiki', :action => :manage_wiki, :partial => 'projects/settings/wiki', :label => :label_wiki},
            {:name => 'repository', :action => :manage_repository, :partial => 'projects/settings/repository', :label => :label_repository},
            {:name => 'boards', :action => :manage_boards, :partial => 'projects/settings/boards', :label => :label_board_plural},
            {:name => 'activities', :action => :manage_project_activities, :partial => 'projects/settings/activities', :label => :enumeration_activities}
            ]
    tabs.select {|tab| User.current.allowed_to?(tab[:action], @project)}
  end

  def parent_project_select_tag(project)
    selected = project.parent
    # retrieve the requested parent project
    parent_id = (params[:project] && params[:project][:parent_id]) || params[:parent_id]
    if parent_id
      selected = (parent_id.blank? ? nil : Project.find(parent_id))
    end

    options = ''
    options << "<option value=''></option>" if project.allowed_parents.include?(nil)
    options << project_tree_options_for_select(project.allowed_parents.compact, :selected => selected)
    content_tag('select', options.html_safe, :name => 'project[parent_id]', :id => 'project_parent_id')
  end

  # Renders a tree of projects as a nested set of unordered lists
  # The given collection may be a subset of the whole project tree
  # (eg. some intermediate nodes are private and can not be seen)
  def render_project_hierarchy(projects)
    s = ''
    if projects.any?
      ancestors = []
      original_project = @project
      projects.each do |project|
        unless project.system?
        # set the project environment to please macros.
        @project = project
        if (ancestors.empty? || project.is_descendant_of?(ancestors.last))
          s << "<ul class='projects #{ ancestors.empty? ? 'root' : nil}'>\n"
        else
          ancestors.pop
          s << "</li>"
          while (ancestors.any? && !project.is_descendant_of?(ancestors.last))
            ancestors.pop
            s << "</ul></li>\n"
          end
        end
        classes = (ancestors.empty? ? 'root' : 'child')
        s << "<li class='#{classes}'><div class='#{classes}'><table><tr><td>" +
               link_to_project(project, {}, :class => "project #{User.current.member_of?(project) ? 'my-project' : nil}")
        #domthu
        s << "</td><td align='left'>" + project.identifier + "</td><td>"
        s << "</td><td align='center'>#{checked_image(project.is_public?)} </td><td>"
        s << "</td><td><div class='due_date'>#{format_date(project.data_dal)} / #{format_date(project.data_al)} </div></td><td>"
        #s << "<div class='wiki description'>#{textilizable(project.short_description, :project => project)}</div>" unless project.description.blank?
        s << "<div class='description'>#{smart_truncate(project.short_description,90)}</div>" unless project.description.blank?
        s << "</td></tr></table></div>\n"
        ancestors << project
          end
      end
      s << ("</li></ul>\n" * ancestors.size)
      @project = original_project
    end
    s.html_safe
  end
  # sandro riquadro progetti di sistema
  def render_sysproject_hierarchy(projects)
    s = ''
    if projects.any?
      original_project = @project
      projects.each do |project|
        if project.system?
          # set the project environment to please macros.
          @project = project
          s << "<div class='sys-projects'><table><tr><td>" +
              link_to_project(project, {}, :class => "project #{User.current.member_of?(project) ? 'my-project' : nil}")
          s << "</td></tr></table></div>\n"
        end
        @project = original_project
      end
    end
    s.html_safe
  end
  # Returns a set of options for a select field, grouped by project.
  def version_options_for_select(versions, selected=nil)
    grouped = Hash.new {|h,k| h[k] = []}
    versions.each do |version|
      grouped[version.project.name] << [version.name, version.id]
    end
    # Add in the selected
    if selected && !versions.include?(selected)
      grouped[selected.project.name] << [selected.name, selected.id]
    end

    if grouped.keys.size > 1
      grouped_options_for_select(grouped, selected && selected.id)
    else
      options_for_select((grouped.values.first || []), selected && selected.id)
    end
  end

  def format_version_sharing(sharing)
    sharing = 'none' unless Version::VERSION_SHARINGS.include?(sharing)
    l("label_version_sharing_#{sharing}")
  end
end
