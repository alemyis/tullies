require 'Ruby_Bosh'
require 'xmpp4r'
require 'xmpp4r/muc/helper/mucclient'
require 'xmpp4r/muc/helper/simplemucclient'

class NoteablechatController < ApplicationController
  def new_boshsession
    username = session[:user_jid].nil? ? get_jid() : session[:user_jid]
    password = session[:user_password].nil? ? NOTEABLECHAT_CONFIG['default_pwd'] : session[:user_password]
    
    xmpp_server = NOTEABLECHAT_CONFIG['xmpp_server']
    xmpp_bosh_port = NOTEABLECHAT_CONFIG['xmpp_bosh_port']
    jid = "#{username}@#{xmpp_server}"
    server_url = "http://#{xmpp_server}:#{xmpp_bosh_port}/http-bind/"
    room = "#{params[:room_jid]}@#{NOTEABLECHAT_CONFIG['muc_namespace']}"
    nickname = "#{username}:~:#{Time.new.tv_sec}" #append timestamp to make sure nickname is unique
    
    @session_jid, @session_id, @session_random_id = RubyBOSH.initialize_session(jid,
                                                                                password,
                                                                                server_url,
                                                                                {:timeout => 20})
  
    render :json => {:jid=>@session_jid, :sid=>@session_id, :rid=>@session_random_id, :room => room, :nickname => nickname}
  end
  
  def get_jid
    if(session[:user_jid].nil?)
      session[:user_jid] = "#{NOTEABLECHAT_CONFIG['guest_jid']}#{rand(9999)}"
      create_jid(session[:user_jid])
    end
    session[:user_jid]
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
