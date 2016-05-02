class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  
  if ! Rails.env.development?
    rescue_from Exception, with: error
  end
  
  before_filter :before_action
  after_filter :after_action
  
protected
  def before_action
    @title = ""
    @dst_url = param( "dst_url", "/" )
    @user_agent = Owrb::UserAgent.new( request.env[ "HTTP_USER_AGENT" ] )
    
    login_key = cookie.get( :login_key, "" )
    @provider_account = ProviderAccount.find_by( login_key: login_key )
    check_login_account
  end
  
  def after_action
  end
  
  def check_login_account
    redirect_to "/account?dst_url=#{Owrb::URL.encode( request.original_url )}" if @provider_account.nil?
    
    Rails.logger.info "[#{Owrb::Time.new}] #{@user_agent} #{request.original_url}"
  end
  
  def param( key, default_value )
    params.key?( key ) ? params[ key ] : default_value
  end
  
  def transaction( &block )
    result = nil
    ActiveRecord::Base.transaction do
      result = block.call
    end
    result
    rescue => err
    if Rails.env.development?
      backtrace = err.backtrace.join( "\n" )
      Rails.logger.error "#{err.message}\n#{backtrace}"
    else
      Rails.logger.error err.message
    end
    raise err
  end
  
  def cookie
    @cookie = Owrb::Rails::Cookie.new( cookies )
  end
  
  def cipher( login_key, account_id )
    cipher = Owrb::Data.cipher
    cipher.key_iv( login_key, "01" * ( ( account_id % 10 ) + 1 ) )
    cipher
  end
  
  def encrypt( cipher, data )
    Owrb::Data::Base64.encode( cipher.encrypt( Owrb::JSON.encode( data ) ) )
  end
  
  def decrypt( cipher, data )
    Owrb::Data::Base64.decode( cipher.decrypt( Owrb::JSON.encode( data ) ) )
  end
  
  def encode( data )
    Owrb::Data::Base64.encode( data )
  end
  
  def decode( data )
    Owrb::Data::Base64.decode( data )
  end
  
  def error( err )
    render :json => { :errmsg => err.message }
  end
end
