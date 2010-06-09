// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults
function remove_fields(link) {  
    $(link).previous("input[type=hidden]").value = "1";  
    $(link).up(".fields").hide();  
}

function add_fields(link, association, content) {  
    var new_id = new Date().getTime();  
    var regexp = new RegExp("new_" + association, "g");  
    $(link).up().insert({  
        before: content.replace(regexp, new_id)  
    });  
}

function duration_calc()
{
    
    var hourBox = $("duration_hours");
    var minuteBox = $("duration_minutes");
    var totalMinutes = Number(hourBox.value * 60) + Number(minuteBox.value);
    var minutes = totalMinutes % 60;
    var hours = (totalMinutes - minutes) / 60;
    
    hourBox.value = hours;
    minuteBox.value = minutes;
    
    var meetingDuration = $('meeting_duration');
    meetingDuration.value = totalMinutes;
    
}