require 'xmpp4r'
require 'xmpp4r/muc/helper/mucclient'
require 'xmpp4r/muc/helper/simplemucclient'

class Noteablechat
    def self.create_room(unique_id)
        muc_name = get_MUC_name(unique_id)
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
    
    def self.get_MUC_name (unique_id)
        muc_name = NOTEABLECHAT_CONFIG['muc_name_constant'].nil? ? 'noteablechat_room_' : NOTEABLECHAT_CONFIG['muc_name_constant']
        muc_name += unique_id
        muc_name
    end
end
