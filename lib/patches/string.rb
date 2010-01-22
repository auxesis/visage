# extracted from Extlib. 
# FIXME: what's the licensing here?
class String
  def camel_case                                                                                                                                    
    return self if self !~ /_/ && self =~ /[A-Z]+.*/                                                                                                
    split('_').map{|e| e.capitalize}.join                                                                                                           
  end   

  def blank?
    strip.empty?
  end
end

