module Redmine
  module Info
    class << self
      def app_name; 'fismine' end
      def url; 'http://monamiweb.it/fismine/' end
      #dom@monamiweb.it
      #def help_url; 'http://www.dom.monamiweb.it/' end
      #def help_url; 'http://www.redmine.org/guide' end
      def help_url; 'http://www.redmine.org/projects/redmine/wiki/Administrator_Guide' end
      def help_user_url; 'http://www.redmine.org/projects/redmine/wiki/User_Guide' end
      def versioned_name; "#{app_name} #{Redmine::VERSION}" end

      # Creates the url string to a specific Redmine issue
      def issue(issue_id)
        url + 'issues/' + issue_id.to_s
      end
    end
  end
end
