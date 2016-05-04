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
    
    login_key = cookie.get( :login_key, "" )
    @provider_account = ProviderAccount.find_by( login_key: login_key )
    check_login_account
    
    @style = Owrb::HTML::Style
    @stylesheets = stylesheets
    @javascripts = javascripts
    @errmsgs = errmsgs
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
  
  def error( err )
    render :json => { :errmsg => err.message }
  end
  
  def stylesheet( name, styles )
    @style.css( name, styles )
  end
  
  def stylesheets
    contents = [
      stylesheet( ".button_black", [
        @style.border({ :border => "1px solid #616261", :radius => "3px" }),
        @style.background({ :linear_gradient => { :color => [ "#7d7e7d", "#0e0e0e" ] } }),
        @style.font({ :size => "20px", :family => "arial", :style => "bold" }),
        @style.text({ :shadow => "-1px -1px 0 rgba( 0, 0, 0, 0.3 )", :color => "#FFFFFF" }),
        [ "margin: 10px 0" ]
      ]),
      stylesheet( ".button_black:hover", [
        @style.border({ :border => "1px solid #4a4b4a" }),
        @style.background({ :linear_gradient => { :color => [ "#646464", "#282828" ] } }),
      ]),
      stylesheet( ".button_black:disabled", [
        @style.border({ :border => "1px solid #bfbfbf" }),
        @style.background({ :color => "#bfbfbf", :image => "none" }),
      ]),
      stylesheet( ".button_blue", [
        @style.border({ :border => "1px solid #15aeec", :radius => "3px" }),
        @style.background({ :linear_gradient => { :color => [ "#49c0f0", "#2CAFE3" ] } }),
        @style.font({ :size => "20px", :family => "arial", :style => "bold" }),
        @style.text({ :shadow => "-1px -1px 0 rgba( 0, 0, 0, 0.3 )", :color => "#FFFFFF" }),
        [ "margin: 10px 0" ]
      ]),
      stylesheet( ".button_blue:hover", [
        @style.border({ :border => "1px solid #1090c3" }),
        @style.background({ :linear_gradient => { :color => [ "#1ab0ec", "#1a92c2" ] } }),
      ]),
      stylesheet( ".button_blue:disabled", [
        @style.border({ :border => "1px solid #bfbfbf" }),
        @style.background({ :color => "#bfbfbf", :image => "none" }),
      ]),
      stylesheet( ".button_green", [
        @style.border({ :border => "1px solid #34740e", :radius => "3px" }),
        @style.background({ :linear_gradient => { :color => [ "#4ba614", "#008c00" ] } }),
        @style.font({ :size => "20px", :family => "arial", :style => "bold" }),
        @style.text({ :shadow => "-1px -1px 0 rgba( 0, 0, 0, 0.3 )", :color => "#FFFFFF" }),
        [ "margin: 10px 0" ]
      ]),
      stylesheet( ".button_green:hover", [
        @style.border({ :border => "1px solid #224b09" }),
        @style.background({ :linear_gradient => { :color => [ "#36780f", "#005900" ] } }),
      ]),
      stylesheet( ".button_green:disabled", [
        @style.border({ :border => "1px solid #bfbfbf" }),
        @style.background({ :color => "#bfbfbf", :image => "none" }),
      ]),
      stylesheet( ".button_purple", [
        @style.border({ :border => "1px solid #8a66f4", :radius => "3px" }),
        @style.background({ :linear_gradient => { :color => [ "#b29af8", "#9174ed" ] } }),
        @style.font({ :size => "20px", :family => "arial", :style => "bold" }),
        @style.text({ :shadow => "-1px -1px 0 rgba( 0, 0, 0, 0.3 )", :color => "#FFFFFF" }),
        [ "margin: 10px 0" ]
      ]),
      stylesheet( ".button_purple:hover", [
        @style.border({ :border => "1px solid #693bf1" }),
        @style.background({ :linear_gradient => { :color => [ "#8e6af5", "#6d47e7" ] } }),
      ]),
      stylesheet( ".button_purple:disabled", [
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
  if ( 640 < width ) width = 640;
  global.content = {
    "width":  width,
    "height": screen.height,
  };
  
  $( "button[type=submit]" ).prop( "disabled", false );
  $( "button[type=submit]" ).attr( "data-disable-with", "*" );
  $( "form" ).on( "submit", function(){
    return check_submit();
  });
})

function check_submit(){
  $( this ).off( "submit" );
  $( this ).submit();
}
EOS
    }]
  end
  
  def errmsgs
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
