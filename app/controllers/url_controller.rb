class UrlController < ApiController
  def parse
    api{
      url = Owrb::URL.parse( param( "url", "" ) )
      {
        :scheme => url.scheme,
        :host   => url.host,
        :port   => url.port,
        :path   => url.path,
        :query  => url.query,
      }
    }
  end
  
  def order
    api{
      @browser = Owrb::Browser.new
      url = param( "url", "" )
      request_orders = Owrb::JSON.decode( param( "request_orders", "[]" ) )
      response_orders = Owrb::JSON.decode( param( "response_orders", "[]" ) )
      @browser.go( url )
      request_orders.each{|order|
        case order.shift
        when "click"
          @browser.click( *order )
        end
      }
      
      results = {}
      document = @browser.document
      response_orders.each{|order|
        key = order.shift
        case order.shift
        when "xpath"
          elements = []
          document.xpath( *order ).each{|element|
            elements.push element.to_h
          }
          results[ key ] = elements
        when "html"
          results[ key ] = @browser.html
        end
      }
      
      {
        :results => results
      }
    }
  end
end
