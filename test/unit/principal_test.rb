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

require File.expand_path('../../test_helper', __FILE__)

class PrincipalTest < ActiveSupport::TestCase
  fixtures :users, :projects, :members, :member_roles

  def test_not_member_of_scope_should_return_users_that_have_no_memberships
    projects = Project.find_all_by_id(1, 2)
    expected = (Principal.all - projects.map(&:memberships).flatten.map(&:principal)).sort
    assert_equal expected, Principal.not_member_of(projects).sort
  end

  context "#like" do
    setup do
      Principal.generate!(:login => 'login')
      Principal.generate!(:login => 'login2')

      Principal.generate!(:firstname => 'firstname')
      Principal.generate!(:firstname => 'firstname2')

      Principal.generate!(:lastname => 'lastname')
      Principal.generate!(:lastname => 'lastname2')

      Principal.generate!(:mail => 'mail@example.com')
      Principal.generate!(:mail => 'mail2@example.com')
    end

    should "search login" do
      results = Principal.like('login')

      assert_equal 2, results.count
      assert results.all? {|u| u.login.match(/login/) }
    end

    should "search firstname" do
      results = Principal.like('firstname')

      assert_equal 2, results.count
      assert results.all? {|u| u.firstname.match(/firstname/) }
    end

    should "search lastname" do
      results = Principal.like('lastname')

      assert_equal 2, results.count
      assert results.all? {|u| u.lastname.match(/lastname/) }
    end

    should "search mail" do
      results = Principal.like('mail')

      assert_equal 2, results.count
      assert results.all? {|u| u.mail.match(/mail/) }
    end
  end

end
