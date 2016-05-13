class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  
  before_filter :before_action
  after_filter :after_action
  
protected
  def before_action
    @title = ""
    @dst_url = param( "dst_url", "/" )
    
    login_key = cookie.get( :login_key, "" )
    @provider_account = ProviderAccount.find_by( login_key: login_key )
    check_login_account
    
    @style = Owrb::HTML::Style
    @stylesheets = stylesheets
    @javascripts = javascripts
    @errmsg = errmsg
  end
  
  def after_action
  end
  
  def check_login_account
    redirect_to "/account?dst_url=#{Owrb::URL.encode( request.original_url )}" if @provider_account.nil?
    
    Rails.logger.info "[#{Owrb::Time.new}] #{request.original_url}"
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
  
  def encode( data )
    Owrb::Data::Base64.encode( data )
  end
  
  def decode( data )
    Owrb::Data::Base64.decode( data )
  end
  
  def stylesheet( name, styles )
    @style.css( name, styles )
  end
  
  def stylesheets
    contents = [
      stylesheet( ".button", [
        @style.border({ :border => "1px solid #616261", :radius => "3px" }),
        @style.background({ :linear_gradient => { :color => [ "#7d7e7d", "#0e0e0e" ] } }),
        @style.font({ :size => "20px", :family => "arial", :style => "bold" }),
        @style.text({ :shadow => "-1px -1px 0 rgba( 0, 0, 0, 0.3 )", :color => "#FFFFFF" }),
        [ "margin: 10px 0" ]
      ]),
      stylesheet( ".button:hover", [
        @style.border({ :border => "1px solid #4a4b4a" }),
        @style.background({ :linear_gradient => { :color => [ "#646464", "#282828" ] } }),
      ]),
      stylesheet( ".button:disabled", [
        @style.border({ :border => "1px solid #bfbfbf" }),
        @style.background({ :color => "#bfbfbf", :image => "none" }),
      ]),
      stylesheet( ".error", [
        @style.font({ :size => "24px", :family => "arial", :style => "bold" }),
        @style.text({ :color => "#FF0000" }),
      ]),
      stylesheet( ".warning", [
        @style.font({ :size => "24px", :family => "arial", :style => "bold" }),
        @style.text({ :color => "#FFCC00" }),
      ]),
    ]
    
    [{
      :content => contents.join( "\n" ),
    }]
  end
  
  def javascripts
    [{
      :content => <<EOS
var global = {};

$(function(){
  opjs.document.set( document );
  global.element = opjs.document.element;
  
  var width = screen.width;
  if ( 1000 < width ) width = 1000;
  global.content = {
    "width":  width,
    "height": screen.height,
  };
  
  $( "button[type=submit]" ).prop( "disabled", false );
  $( "button[type=submit]" ).attr( "data-disable-with", "*" );
  $( "form" ).on( "submit", function(){
    return check_submit();
  });
  
  $( "#main" ).width( global.content.width );
})

function check_submit(){
  $( this ).off( "submit" );
  $( this ).submit();
}
EOS
    }]
  end
  
  def errmsg
    {
      :not_found => "該当データが存在しませんでした"
    }
  end
  
  def time_limit( time_limit )
    now = Time.now
    diff = Owrb::Time.new( now ).diff( time_limit )
    if 0 == diff[ :total_seconds ]
      at = "0秒"
    else
      at = ""
      at = "#{at}#{diff[ :days ]}日" if 0 < diff[ :days ]
      at = "#{at}#{diff[ :hours ]}時間" if 0 < diff[ :hours ]
      at = "#{at}#{diff[ :minutes ]}分" if 0 < diff[ :minutes ]
      at = "#{at}#{diff[ :seconds ]}秒" if 0 < diff[ :seconds ]
    end
    is_finished = ( time_limit <= now )
    at = is_finished ? "終了：約#{at}前" : "締切：約#{at}後"
    {
      :at          => at,
      :time        => Owrb::Time.format( :ymdhms, time_limit ),
      :is_finished => is_finished,
    }
  end
end
