var BOSH_SERVICE = '/http-bind/';

var NoteableChat = {
    connection: null,
    room: null,
    nickname: null,
    joined: null,
    participants: null,
    lastmessagefrom: null,
    
    //
    // Send msg based on type ('chat' or 'groupchat')
    //
    sendMsg : function(body){
	if (body.match(/^\/topic (.+)/)) {
	    var topic = body.replace(/^\/topic (.+)/,"$1");
	    return NoteableChat.sendTopic(topic);
	}else{
	    return NoteableChat.sendIM(body);
	}
    },
    //
    // Send group message
    //
    sendIM : function(body){
	Strophe.debug('Sending IM...');
	if(NoteableChat._isNullOrEmpty(body) ) return false;
        
        NoteableChat.connection.send($msg({
            to: NoteableChat.room,
            type: "groupchat"
            }).c('body').t(body));
	return true;
    },
    //
    // Send special message to room topic
    //
    sendTopic : function(topic){       
	Strophe.debug('Sending topic...');
	NoteableChat.connection.send($msg({
            to: NoteableChat.room,
            type: "groupchat"}).c('subject').t(topic)); 
	
	return false;
    },
    //
    //Reconnect to chat room requesting full chat history
    //
    getFullHistory : function(){
	NoteableChat.logout();
	$('#noteablechat_chatlog').empty();
	NoteableChat.joinMUC({"since" : '1970-01-01T00:00:00Z'}); //get full chat history
    },
  
    //
    //Establish connection
    //option 1 - from hidden fields with authenticated SID from server side
    //
    loginSIDOnPage : function(data){
        Strophe.info('Login started...');
	NoteableChat.room = data.room;
	NoteableChat.nickname = data.nickname;
        NoteableChat.connection.attach(data.jid, data.sid, data.rid, NoteableChat.onConnect);
        Strophe.info('Login complete.');
    },
    //
    //Establish connection
    //option 2- from server side json store request for SID
    //
    loginSIDFromServer : function(serviceURL){
        Strophe.info('Login started...');
        
        Strophe.debug('Getting SID from SID service...');
            
        $.getJSON(serviceURL.jsonURL, function(data) {
            Strophe.debug('SID service returned...');
            try
            {
		NoteableChat.room = data.room;
		NoteableChat.nickname = data.nickname;
		NoteableChat.connection.attach(data.jid, data.sid, data.rid, NoteableChat.onConnect);
              
		Strophe.info('Login complete.');
              
            }catch(e)
            {
		Strophe.error('Login failed: ' + e.message);
            }
        
        });
    },
    //
    //Establish connection
    //option 3 - from hidden fields with username/password
    //
    loginUsernamePassword : function(data){
        Strophe.info('Login started...');
	NoteableChat.room = data.room;
	NoteableChat.nickname = data.nickname;
        NoteableChat.connection.connect(data.jid, data.password, NoteableChat.onConnect);
        Strophe.info('Login complete.');
    },
    //
    //Kill connection
    //
    logout : function(){
	Strophe.info('Logout...')
	NoteableChat.connection.send($pres({to: NoteableChat.room + "/" + NoteableChat.nickname, type: 'unavailable'}));
	NoteableChat.connection.disconnect();
    },
  
    //
    //Re-login
    //
    refreshconnection : function(){
	Strophe.info('Refreshing connection...');
	
	if(NoteableChat.status == Strophe.Status.CONNECTED)
	    NoteableChat.logout();
	else
	    $(document).trigger('connect');
	
	return false;
    },
  
    //
    //Listen to connection status
    //On on Connected: Join chat room
    //
    onConnect : function (status){
	var ready = false;
	Strophe.info('Connection status: ' + status);
	switch (status)
	{
	    case Strophe.Status.DISCONNECTED:
		Strophe.info('Connection status: disconnected.');
		$(document).trigger('disconnected');
		break;
	    case Strophe.Status.CONNECTED:
	    case Strophe.Status.ATTACHED:
		Strophe.info('Strophe is connected.');
		$(document).trigger('connected');
		break;
	}
    },
      
    //
    //Listen for presence
    //
    onPresence : function(pres){
        var from = $(pres).attr('from');
        var room = Strophe.getBareJidFromJid(from);
        
        if(room.toLowerCase() === NoteableChat.room.toLowerCase()){
            var nickname = Strophe.getResourceFromJid(from);
            
            if($(pres).attr('type') === 'error' && !NoteableChat.joined){
                NoteableChat.connection.disconnect();
            } else if (!NoteableChat.participants[nickname] && $(pres).attr('type') !== 'unavailable'){
                var user_jid = $(pres).find('item').attr('jid');
                NoteableChat.participants[nickname] = user_jid || true;
                $('#noteablechat_roster').append('<li id="li' + nickname + '">' + NoteableChat._stripTimeStampFromNickname(nickname) + '</li>');
                
                if(NoteableChat.joined){
                    $(document).trigger('user_joined', nick);
                }
            } else if (NoteableChat.participants[nickname] && $(pres).attr('type') === 'unavailable'){
                $('#li_' + nickname).remove();
		NoteableChat.participants[nickname] = false;
                $(document).trigger('user_left', nickname);
            }
        }
        
        if($(pres).attr('type') !== 'error' && !NoteableChat.joined){
            if($(pres).find("status[code='110']").length > 0){
                //check if server changed our nickname
                if($(pres).find("status[code='210']").length > 0){
                    NoteableChat.nickname = Strophe.getResourceFromJid(from);
                }
                
                $(document).trigger('room_joined');
            }
        }
        return true;
    },
    //
    //Listen to public xmpp stanzas
    //
    onPublicMessage : function(msg) {
        var from = $(msg).attr('from');
        var room = Strophe.getBareJidFromJid(from);
        var nickname = Strophe.getResourceFromJid(from);
        
        if(room.toLowerCase() === NoteableChat.room.toLowerCase()){
            //message from room or user?
            var notice = !nickname;
            
            var body = $(msg).children('body').text();
            
            var delayed = $(msg).children('delay').length > 0 ||
                $(msg).children("x[xmlns='jabber:x:delay']").length > 0;
		
	    var timestamp = new Date().toTimeString();
	    if(delayed){
		timestamp = $(msg).children('delay').attr('stamp');
	    }
	    var subject = $(msg).children('subject').text();
            if(subject){
                $('#noteablechat_topic').text('Currently Discussing:' + subject);
            }else if(!notice){
		var logmsg = '<div>';
		if(NoteableChat.lastmessagefrom != nickname) //skip nickname if from same nickname
		{
		    logmsg += '<div class="noteablechat_log_nickname">' + NoteableChat._stripTimeStampFromNickname(nickname) + ': </div>';
		}
		logmsg += '<div class="noteablechat_log_timestamp">' + timestamp + '</div><div class="noteablechat_log_message">' + body + '</div></div>';
		
                NoteableChat.addMessage(logmsg);
		NoteableChat.lastmessagefrom = nickname;
	    }else{
                NoteableChat.addMessage('<div>***' + body + '</div>');
            }
        }
        return true;
    },
    //
    //Append to chatlog
    //
    addMessage : function(msg){
        var chat = $('#noteablechat_chatlog').get(0);
        var isAtBottom = chat.scrollTop >= chat.scrollHeight - chat.clientHeight;
        
        $('#noteablechat_chatlog').append(msg);
        
        if(isAtBottom){
            chat.scrollTop = chat.scrollHeight;
        }
    },
    
    //
    //Helpers
    //
    _htmlEncode : function (value){ 
	return $('<div/>').text(value).html(); 
    }, 
    _htmlDecode : function(value){ 
	return $('<div/>').html(value).text(); 
    },
    _isNullOrEmpty : function(value){
	if(!value
	   ||
	   value.lengh == 0
	   ||
	   value == '\n'
	   ){
	  return true;
	}
	return false;
    },
    _log : function (level, msg) {
	try{
	    var dateTime = new Date();
	    msg = '[' + dateTime.getHours() + ':' + dateTime.getMinutes() + ':' + dateTime.getSeconds() + ':' + dateTime.getMilliseconds() +'] ' + msg;
	    if(console)
		console.log(msg);
	}catch(e){}
    },
    _stripTimeStampFromNickname : function(nickname){
	//e.g. Guest1324:~:1278889735, alem:~:1278889735
	return nickname.split(':~:')[0];
    }
}

//
//Bind events
//
$(document).bind('connect', function(e, d){
   NoteableChat.connection = new Strophe.Connection(BOSH_SERVICE);
   NoteableChat.loginSIDFromServer({jsonURL: $('#notablechat_service_url').val()});
});

$(document).bind('connected', function(){
   NoteableChat.joined = false;
   NoteableChat.participants = {};
   NoteableChat.connection.send($pres().c('priority').t('-1'));
   NoteableChat.connection.addHandler(NoteableChat.onPresence, null, 'presence', null, null,  null); 
   NoteableChat.connection.addHandler(NoteableChat.onPublicMessage, null, 'message', 'groupchat', null,  null); 
   NoteableChat.connection.send($pres({to: NoteableChat.room + '/' + NoteableChat.nickname}).c('x', {xmlns: Strophe.NS.MUC}));
});

$(document).bind('disconnected', function(){
    NoteableChat.connection = null;
    $('#noteablechat_topic').empty();
    $('#noteablechat_roster').empty();
    $('#noteablechat_chatlog').empty();
});

$(document).bind('room_joined', function(){
    NoteableChat.joined = true;
    NoteableChat.addMessage("<div class='noteablechat_log_i_joined'>*** Room joined.</div>")
});

$(document).bind('user_joined', function(e, nickname){
    NoteableChat.addMessage("<div class='noteablechat_log_user_joined'>" + NoteableChat._stripTimeStampFromNickname(nickname) + " joined.</div>")
});

$(document).bind('user_left', function(e, nickname){
    NoteableChat.addMessage("<div class='noteablechat_log_user_left'>" + NoteableChat._stripTimeStampFromNickname(nickname) + " left.</div>")
});

//
//UI action listerners
//
$('#noteablechat_msgArea').live('keypress', function(e) {
    if(e.keyCode == 13) {
        e.preventDefault();        
        NoteableChat.sendMsg($(this).val());
        $(this).val('');
    }
});

$('#noteablechat_postButton').live('click', function(e){
    NoteableChat.sendMsg($('#noteablechat_msgArea').val());
    $('#noteablechat_msgArea').val('');
});

//
//Start connection on load and close on unload
//
window.onload = function() {
 $(document).trigger('connect');
};
window.onbeforeunload = function(){
    NoteableChat.logout();
};
