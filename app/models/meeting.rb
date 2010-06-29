require 'xmpp4r'
require 'xmpp4r/muc/helper/mucclient'
require 'xmpp4r/muc/helper/simplemucclient'

class Meeting < ActiveRecord::Base
    #attr_accessible :topic, :description, :location, :duration, :start_at
  
    has_many :items, :dependent =>:destroy
    has_many :goals, :dependent =>:destroy
    has_many :agendas, :dependent =>:destroy
  
    accepts_nested_attributes_for :goals, :agendas, :reject_if => lambda { |a| a[:content].blank? }, :allow_destroy => true
  
    def getHours
        if(duration.nil?)
            ""
        else
            duration / 60
        end
    end
    def getMinutes
        if(duration.nil?)
            ""
        else
            duration % 60
        end
    end
  
    def after_create
        muc_name = get_MUC_name()
        if NOTEABLECHAT_CONFIG['create_muc']
            jid = "#{NOTEABLECHAT_CONFIG['username']}@#{NOTEABLECHAT_CONFIG['xmpp_server']}"
            client = Jabber::Client.new(jid)
            client.connect
            client.auth("#{NOTEABLECHAT_CONFIG['password']}")
            client.send(Jabber::Presence.new.set_show(:chat).set_status('backend'))
      
            muc = Jabber::MUC::MUCClient.new(client)
            muc.join(Jabber::JID.new("#{muc_name}@#{NOTEABLECHAT_CONFIG['muc_namespace']}/noteablechat"))
            muc.configure('muc#roomconfig_roomname' => "#{muc_name}",
                          'muc#roomconfig_persistentroom' => 1,
                          'muc#roomconfig_changesubject' => 1)
            
            muc.exit
            client.close
        end   
    end
    
    def get_MUC_name
        muc_name = NOTEABLECHAT_CONFIG['muc_name_constant'].nil? ? 'Noteablechat_Meeting_Room_' : NOTEABLECHAT_CONFIG['muc_name_constant']
        muc_name += self.id.to_s
        muc_name
    end
end
