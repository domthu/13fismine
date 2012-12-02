module EditorialHelper
  include FeesHelper

  def highlight_tokens(text, tokens)
    return text unless text && tokens && !tokens.empty?
    re_tokens = tokens.collect {|t| Regexp.escape(t)}
    regexp = Regexp.new "(#{re_tokens.join('|')})", Regexp::IGNORECASE
    result = ''
    text.split(regexp).each_with_index do |words, i|
      if result.length > 1200
        # maximum length of the preview reached
        result << '...'
        break
      end
      words = words.mb_chars
      if i.even?
        result << h(words.length > 100 ? "#{words.slice(0..44)} ... #{words.slice(-45..-1)}" : words)
      else
        t = (tokens.index(words.downcase) || 0) % 4
        result << content_tag('span', h(words), :class => "highlight token-#{t}")
      end
    end
    result
  end

  def type_label(t)
    l("label_#{t.singularize}_plural", :default => t.to_s.humanize)
  end

  def project_select_tag
    options = [[l(:label_project_all), 'all']]
    options << [@project.name, ''] unless @project.nil?
    label_tag("scope", l(:description_project_scope), :class => "hidden-for-sighted") +
    select_tag('scope', options_for_select(options, params[:scope].to_s)) if options.size > 1
  end

  def render_results_by_type(results_by_type)
    links = []
    # Sorts types by results count
    results_by_type.keys.sort {|a, b| results_by_type[b] <=> results_by_type[a]}.each do |t|
      c = results_by_type[t]
      next if c == 0
      text = "#{type_label(t)} (#{c})"
      links << link_to(h(text), :q => params[:q], :titles_only => params[:titles_only],
                       :all_words => params[:all_words], :scope => params[:scope], t => 1)
    end
    ('<ul>' + links.map {|link| content_tag('li', link)}.join(' ') + '</ul>') unless links.empty?
  end

  #Override plugin act_as_event to change url from BE to FE
  def event_url_fs(e = nil,  options = {})
    evturl = e.event_url(options)
    #puts evturl
    #puts "#####################"
    #printf("evturl    --->   %s", evturl[:controller])
    if (evturl[:controller] == "news")
        evturl[:controller] = "editoriale"
        evturl[:action] = "quesito"
    end
    if (evturl[:controller] == "issues")
        evturl[:controller] = "editoriale"
        evturl[:action] = "articolo"
    end
    if (evturl[:controller] == "projects")
        evturl[:controller] = "editoriale"
        evturl[:action] = "newsletter"
    end
    #url = url.gsub(/\/news\//, '/editoriale/quesito/').gsub(/\/issues\//, '/editoriale/articolo/').gsub(/\/projects\//, '/editoriale/newsletter/')
    return evturl
  end

end
