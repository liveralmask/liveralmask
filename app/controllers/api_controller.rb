class ApiController < ActionController::Base
  def initialize
    super
    
    @browser = nil
  end
  
protected
  def param( key, default_value )
    params.key?( key ) ? params[ key ] : default_value
  end
  
  def api( &block )
    begin
      result = block.call
    rescue => err
      result = {
        :errmsg => err.message
      }
      
      if Rails.env.development?
        backtrace = err.backtrace.join( "\n" )
        Rails.logger.error "#{err.message}\n#{backtrace}"
      end
    end
    render :json => result
    
    @browser.quit if ! @browser.nil?
  end
end
