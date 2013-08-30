module EditorialHelper
  include FeesHelper #getdate
  include AttachmentsHelper


  def highlight_tokens(text, tokens)
    return text unless text && tokens && !tokens.empty?
    re_tokens = tokens.collect { |t| Regexp.escape(t) }
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
    results_by_type.keys.sort { |a, b| results_by_type[b] <=> results_by_type[a] }.each do |t|
      c = results_by_type[t]
      next if c == 0
      text = "#{type_label(t)} (#{c})"
      links << link_to(h(text), :q => params[:q], :titles_only => params[:titles_only],
                       :all_words => params[:all_words], :scope => params[:scope], t => 1)
    end
    ('<ul>' + links.map { |link| content_tag('li', link) }.join(' ') + '</ul>') unless links.empty?
  end

#Override plugin act_as_event to change url from BE to FE
  def event_url_fs(e = nil, options = {})
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

    #url = url.gsub(/\/news\//, '/editoriale/quesito_full/').gsub(/\/issues\//, '/editoriale/articolo/').gsub(/\/projects\//, '/editoriale/newsletter/')
    return evturl
  end

  def url_for_result(e = nil, options = {})
      evturl = e.event_url(options)
    #puts evturl
    #puts "#####################"
    #printf("evturl    --->   %s", evturl[:controller])
    if (evturl[:controller] == "news")

      return link_to highlight_tokens(truncate(e.title, :length => 255), @tokens), url_for(:controller => 'editorial', :action => 'quesito_show', :id => e.id.to_s, :slug => h(truncate(e.title, :length => 125).to_slug))
    end
    if (evturl[:controller] == "issues")
      if e.is_convegno?
        return link_to highlight_tokens(truncate(e.subject, :length => 255), @tokens),  url_for(:controller => 'editorial', :action => 'evento', :id => e.id.to_s, :slug => h(truncate(e.subject, :length => 125).to_slug))
      else
        return link_to highlight_tokens(truncate(e.subject, :length => 255), @tokens), url_for(:controller => 'editorial', :action => "articolo", :topmenu_key => e.section.top_section.top_menu.key, :topsection_key => e.section.top_section.key, :article_id => e.id.to_s, :article_slug => h(truncate(e.subject, :length => 125).to_slug))
      end
    end
    if (evturl[:controller] == "projects")
      #evturl[:controller] = "editoriale"
      #evturl[:action] = "newsletter"
      return link_to highlight_tokens(truncate(e.name, :length => 255), @tokens) ,url_for(:controller => 'editorial', :action => 'edizione', :id => e.id.to_s, :slug => h(truncate(e.name, :length => 125).to_slug))
    end
    #url = url.gsub(/\/news\//, '/editoriale/quesito_full/').gsub(/\/issues\//, '/editoriale/articolo/').gsub(/\/projects\//, '/editoriale/newsletter/')
    flash[:error] = "Risultati di ricerca: errore nel reindirizzamento link "
    redirect_to :back
  end
  def fburl(articolo)
    s= 'https://www.facebook.com/sharer/sharer.php?s=100&p%5Btitle%5D=' + articolo.subject  + '&p%5Burl%5D=http%3A%2F' + link_to_articolo(articolo, :only_path => false) +
    '&p%5Bsummary%5D=' + 'sommario' +
        '&p%5Bimages%5D%5B0%5D=' + 'immagine'
     return s
  end


end
