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

module NewsHelper

  include FeesHelper
  include IssuesHelper

  def default_quesito_name(user=User.current)
    s = "QUESITO N. " + user.id.to_s
    num_quesito = "QUESITO N. 195 del 14/11/2005 - utente servizi Fiscosport n."
    return s
  end
end
