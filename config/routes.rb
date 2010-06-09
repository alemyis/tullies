Allin::Application.routes.draw do |map|
  map.home '', :controller => 'meetings', :action => 'index'
  
  map.meeting_topic_new 'meetings/topic', :conditions => { :method => :get  }, :controller => 'meetings', :action => 'topic_get'
  map.meeting_topic_new_post 'meetings/topic', :conditions => { :method => :post  }, :controller => 'meetings', :action => 'topic_post'
  map.meeting_topic_get 'meetings/:id/topic', :conditions => { :method => :get  }, :controller => 'meetings', :action => 'topic_get'
  map.meeting_topic_post 'meetings/:id/topic', :conditions => { :method => :post }, :controller => 'meetings', :action => 'topic_post'
  
  map.meeting_goal_get 'meetings/:id/goals', :conditions => { :method => :get  }, :controller => 'meetings', :action => 'goal_get'
  map.meeting_goal_post 'meetings/:id/goals', :conditions => { :method => :post }, :controller => 'meetings', :action => 'goal_post'
  
  map.meeting_agenda_get 'meetings/:id/agendas', :conditions => { :method => :get  }, :controller => 'meetings', :action => 'agenda_get'
  map.meeting_agenda_post 'meetings/:id/agendas', :conditions => { :method => :post }, :controller => 'meetings', :action => 'agenda_post'
    
  map.meeting_done 'meetings/:id/done', :conditions => { :method => :get  }, :controller => 'meetings', :action => 'done'
  
  #resources :meetings

end
