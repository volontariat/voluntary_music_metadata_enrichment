module LastfmRequest
  def self.included(base)
    base.extend ClassMethods
  end
  
  def lastfm_request(lastfm, resource, method, error_message_reqexp, params = {})
    self.class.lastfm_request_class_method(lastfm, resource, method, error_message_reqexp, params)
  end

  module ClassMethods
    def lastfm_request_class_method(lastfm, resource, method, error_message_reqexp, params = {})
      response = nil
      raise_parse_exception = params.delete(:raise_parse_exception)
      
      begin
        i = 1
        
        3.times do
          begin
            response = lastfm.send(resource).send(method, params)
            
            break
          rescue Timeout::Error => e 
            puts "lastfm: timeout for ##{i} time"
            sleep 60 
          rescue ArgumentError => e
            if e.message.match('File does not exist')
              puts "lastfm: 'File does not exist' sleep 60 seconds for ##{i} time ..."
              sleep 60
            else
              raise e
            end
          end
          
          i += 1
        end
      rescue Lastfm::ApiError => e
        raise e unless !error_message_reqexp.nil? && e.message.match(error_message_reqexp)
      rescue REXML::ParseException => e
        raise e if raise_parse_exception
      end
      
      response
    end
  end
end