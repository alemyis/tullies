
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
      Noteablechat.create_room(self.id.to_s)
    end
    
end
