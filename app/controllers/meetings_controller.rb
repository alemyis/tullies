require 'Ruby_Bosh'
require 'xmpp4r'
require 'xmpp4r/muc/helper/mucclient'
require 'xmpp4r/muc/helper/simplemucclient'

class MeetingsController < ApplicationController
  def index
    @meetings = Meeting.all
  end
  
  def show
    @meeting = Meeting.find(params[:id])
  end
  
  def new
    redirect_to '/meetings/topic'
  end
  
  def topic_get
    @meeting = nil 
    if params[:id].nil?
      @meeting = Meeting.new
    else
      @meeting = Meeting.find(params[:id])
    end
    
    respond_to do |format|
      format.html {render :template => "meetings/topic" }
    end
  end
  
  def topic_post
    @meeting = nil 
    if params[:id].nil?
      @meeting = Meeting.new(params[:meeting])
      if @meeting.save
        redirect_to meeting_goal_get_path(:id => @meeting.id)
      end
    else
      @meeting = Meeting.find(params[:id])
      if @meeting.update_attributes(params[:meeting])
        redirect_to meeting_goal_get_path(:id => @meeting.id)
      end
    end
  end
  
  def goal_get
    @meeting = Meeting.find(params[:id])
    if @meeting.goals.empty?
      1.times { @meeting.goals.build }
    end
    
    respond_to do |format|
      format.html {render :template => "meetings/goals" }
    end
  end
  
  def goal_post
    @meeting = Meeting.find(params[:id])
    if @meeting.update_attributes(params[:meeting])
      redirect_to meeting_agenda_get_path(:id => @meeting.id)
    end
  end
  
  def agenda_get
    @meeting = Meeting.find(params[:id])
    if @meeting.agendas.empty?
      1.times { @meeting.agendas.build }
    end
    respond_to do |format|
      format.html {render :template => "meetings/agendas" }
    end
  end
  
  def agenda_post
    @meeting = Meeting.find(params[:id])
    if @meeting.update_attributes(params[:meeting])
      redirect_to meeting_done_path(:id => @meeting.id)
    end
  end
  
  def done
    @meeting = Meeting.find(params[:id])
    respond_to do |format|
      format.html {render :template => "meetings/show" }
    end
  end
  
  def create
    @meeting = Meeting.new(params[:meeting])
    if @meeting.save
      if request.referer.include? "/topic"
        redirect_to :action => 'goal', :id => @meeting.id
      elsif request.referer.include? "/goals"
        redirect_to :action => 'agenda', :id => @meeting.id
      elsif request.referer.include? "/agendas"
        redirect_to @meeting
      else  
        flash[:notice] = "Successfully created meeting."
        redirect_to @meeting
      end
      
    else
      render :action => 'new'
    end
  end
  
  def edit
    @meeting = Meeting.find(params[:id])
  end
  
  def update
    @meeting = Meeting.find(params[:id])
    if @meeting.update_attributes(params[:meeting])
      if request.referer.include? "/topic"
        redirect_to :action => 'goal', :id => @meeting.id
      elsif request.referer.include? "/goals"
        redirect_to :action => 'agenda', :id => @meeting.id
      elsif request.referer.include? "/agendas"
        redirect_to @meeting
      else  
        flash[:notice] = "Successfully updated meeting."
        redirect_to @meeting
      end
    else
      render :action => 'edit'
    end
  end
  
  def destroy
    @meeting = Meeting.find(params[:id])
    @meeting.destroy
    flash[:notice] = "Successfully destroyed meeting."
    redirect_to meetings_url
  end
  
  def new_boshsession
    
    @meeting = Meeting.find(params[:id])
    xmpp_server = NOTEABLECHAT_CONFIG['xmpp_server']
    xmpp_bosh_port = NOTEABLECHAT_CONFIG['xmpp_bosh_port']
    username = get_jid()
    password = NOTEABLECHAT_CONFIG['default_pwd']
    jid = "#{username}@#{xmpp_server}"
    server_url = "http://#{xmpp_server}:#{xmpp_bosh_port}/http-bind/"
    room = "#{@meeting.get_MUC_name()}@#{NOTEABLECHAT_CONFIG['muc_namespace']}"
    nickname = "#{username}#{Time.new.tv_sec}"
    
    @session_jid, @session_id, @session_random_id = RubyBOSH.initialize_session(jid,
                                                                                password,
                                                                                server_url,
                                                                                {:timeout => 20})
  
    render :json => {:jid=>@session_jid, :sid=>@session_id, :rid=>@session_random_id, :room => room, :nickname => nickname}
  end
  
  def get_jid
    if(session[:guest_jid].nil?)
      session[:guest_jid] = "#{NOTEABLECHAT_CONFIG['guest_jid']}#{rand(9999)}"
      create_jid(session[:guest_jid])
    end
    session[:guest_jid]
  end

  def create_jid(username)
    jid = "#{username}@#{NOTEABLECHAT_CONFIG['xmpp_server']}"
    client = Jabber::Client.new(jid)
    client.connect(nil, NOTEABLECHAT_CONFIG['c2s_port'].to_i)
    client.register(NOTEABLECHAT_CONFIG['default_pwd'])
    
    client.close
    return username
  end
end
