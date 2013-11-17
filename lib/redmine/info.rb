module Redmine
  module Info
    class << self
      def app_name; 'FISMINE for Fiscosport' end
      def url; 'http://fiscosport.it/' end
      def app_name_fs; 'Fiscosport' end
      def url_fs; 'http://fiscosport.it/'  end
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
