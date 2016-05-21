class SimpolleController < ApplicationController
  def create
    @question = Owrb::JSON.decode( param( "question", '{"title":"", "choices":{"0":"", "1":"", "2":"", "3":"", "4":""}}' ) )
    @question[ "time_limits" ] = {}
    7.times{|index|
      day = index + 1
      @question[ "time_limits" ][ "#{day}日後に終了" ] = day
    }
    @question[ "time_limit" ] = "1" if ! @question.key?( "time_limit" )
    
    @javascripts.push({
      :content => <<EOS
$(function(){
  $( "textarea" ).keyup(function(){
    global.check_preview();
  });
  $( "input" ).keyup(function(){
    global.check_preview();
  });
  global.check_preview();
})

global.check_preview = function(){
  var disabled = true;
  do{
    if ( 0 == $( "#question_title" ).val().length ) break;
    
    var choices = $( ".question_choice" ).map(function( i, element ){
      return $( this ).val();
    });
    
    for ( var i = 0; i < choices.length; ++i ){
      if ( 0 < choices[ i ].length ){
        disabled = false;
        break;
      }
    }
  }while ( false );
  $( "#preview" ).prop( "disabled", disabled );
};
EOS
    })
    
    return if @question[ "title" ].empty?
    return if ! request.post?
    return if ! params.key?( "create" )
    
    choices = @question[ "choices" ].select{|key, value| ! value.empty?}.values
    return if choices.empty?
    
    result = transaction{
      question = SimpolleQuestion.find_by( account_id: @provider_account.account_id )
      if ! question.nil?
        SimpolleQuestionChoice.delete_all( simpolle_question_id: question.id )
        question.delete
      end
      
      question = SimpolleQuestion.new
      question.question = encode( Owrb::JSON.encode({
        :title      => @question[ "title" ],
        :choices    => choices,
        :time_limit => @question[ "time_limit" ].to_i.days.from_now( Time.now ).to_i,
      }))
      question.result = encode( Owrb::JSON.encode({
        :choices => choices.collect{|choice| 0}
      }))
      question.account_id = @provider_account.account_id
      question.save!
      
      {
        :question_key => encode( question.id.to_s )
      }
    }
    
    redirect_to "/simpolle/view/#{result[ :question_key ]}"
  end
  
  def preview
    @question = param( "question", {
      "title"   => "",
      "choices" => {
        "0" => "",
        "1" => "",
        "2" => "",
        "3" => "",
        "4" => "",
      },
      "time_limit" => "1",
    })
    
    time_limit = time_limit( @question[ "time_limit" ].to_i.days.from_now( Time.now ) )
    @time_limit = "#{time_limit[ :at ]}(#{time_limit[ :time ]})"
    
    delete_question = SimpolleQuestion.find_by( account_id: @provider_account.account_id )
    if ! delete_question.nil?
      @delete_question = Owrb::JSON.decode( decode( delete_question.question ) )
      @delete_question[ :key ] = encode( delete_question.id.to_s )
    end
  end
  
  def view
    @question_choice = -1
    begin
      @question_key = param( "question_key", "" )
      if @question_key.empty?
        question = SimpolleQuestion.find_by( account_id: @provider_account.account_id )
        if ! question.nil?
          @question_key = encode( question.id.to_s )
          redirect_to "/simpolle/view/#{@question_key}"
        end
      else
        question_id = decode( @question_key ).to_i
        question = SimpolleQuestion.find_by( id: question_id )
        if ! question.nil?
          question_choice = SimpolleQuestionChoice.find_by( simpolle_question_id: question_id )
          @question_choice = question_choice.choice if ! question_choice.nil?
        end
      end
    rescue => err
      question = nil
    end
    
    return if question.nil?
    
    @question = Owrb::JSON.decode( decode( question.question ) )
    time_limit = time_limit( Time.at( @question[ "time_limit" ] ) )
    @time_limit = "#{time_limit[ :at ]}(#{time_limit[ :time ]})"
    @is_finished = time_limit[ :is_finished ]
    
    result = Owrb::JSON.decode( decode( question.result ) )
    total = result[ "choices" ].inject{|sum, value| sum + value}
    @question[ :total ] = total.to_s( :delimited )
    @question[ :result ] = @question[ "choices" ].collect{|text| { :text => "" }}
    if @is_finished || ( question.account_id == @provider_account.account_id )
      max_percentage = 0
      result[ "choices" ].each_with_index{|num, i|
        percentage = ( 0 == total ) ? 0.0 : ( ( num.to_f / total ) * 100 ).round( 2 )
        if 0.0 == percentage
          percentage = 0
        elsif 1.0 <= percentage
          percentage = percentage.to_i
        end
        
        @question[ :result ][ i ][ :text ]  = "#{percentage}%<br>(#{num.to_s( :delimited )})"
        @question[ :result ][ i ][ :percentage ] = percentage
        
        max_percentage = percentage if max_percentage < percentage
      }
      
      @question[ :result ].each_with_index{|result, i|
        if max_percentage == result[ :percentage ]
          result[ :text ] = "<b>#{result[ :text ]}</b>"
          @question[ :result ][ i ] = result
        end
      }
    end
  end
  
  def choice
    result = transaction{
      question_key = param( "question_key", "" )
      choice = param( "choice", "-1" ).to_i
      cancel = param( "cancel", "-1" ).to_i
      question_id = decode( question_key ).to_i
      question = SimpolleQuestion.find_by( id: question_id )
      question_choice = SimpolleQuestionChoice.find_by( simpolle_question_id: question_id, account_id: @provider_account.account_id )
      
      result = Owrb::JSON.decode( decode( question.result ) )
      
      if 0 <= choice
        if question_choice.nil?
          question_choice = SimpolleQuestionChoice.new
          question_choice.simpolle_question_id = question_id
          question_choice.account_id = @provider_account.account_id
        else
          result[ "choices" ][ question_choice.choice ] -= 1
        end
        
        question_choice.choice = choice
        question_choice.save!
        
        result[ "choices" ][ choice ] += 1
      else
        question_choice.delete if ! question_choice.nil?
        
        result[ "choices" ][ cancel ] -= 1
      end
      
      question.result = encode( Owrb::JSON.encode( result ) )
      question.save!
      
      {
        :question_key => question_key
      }
    }
    
    redirect_to "/simpolle/view/#{result[ :question_key ]}"
  end
  
protected
  def stylesheets
    contents = [
      stylesheet( "div.question_result", [
        @style.text({ :align => "left" }),
        [ "width: 100%" ],
      ]),
      stylesheet( "div.question_result_num", [
        @style.text({ :align => "right" }),
        @style.font({ :size => "24px" }),
        [ "width: 30%; margin: auto 0" ],
      ]),
      stylesheet( "textarea.question_title", [
        @style.font({ :size => "30px" }),
        [ "width: 70%; resize:none" ],
      ]),
      stylesheet( "div.question_title", [
        @style.font({ :size => "30px" }),
        @style.text({ :align => "left", :style => "bold" }),
        [ "width: 70%" ],
      ]),
      stylesheet( "div.question_choice", [
        [ "width: 70%; margin: auto 0" ],
      ]),
      stylesheet( "div.question_choice_text", [
        @style.font({ :size => "30px" }),
        [ "margin: auto 10px; padding: 0" ],
      ]),
      stylesheet( "input.question_choice", [
        @style.font({ :size => "30px" }),
        [ "width: 70%; margin: 10px 0" ],
      ]),
      stylesheet( "select.question_time_limits", [
        @style.font({ :size => "20px" }),
        [ "width: 70%" ],
      ]),
      stylesheet( "div.question_time_limit", [
        @style.font({ :size => "20px" }),
        @style.text({ :color => "#FF0000" }),
      ]),
      stylesheet( "div.question_time_limit_finish", [
        @style.font({ :size => "20px" }),
        @style.text({ :color => "#0000FF" }),
      ]),
      stylesheet( ".question_select", [
        [ "width: 100%; padding: 10px 0" ],
      ]),
      stylesheet( ".question_button_select", [
        @style.border({ :border => "1px solid #15aeec", :radius => "3px" }),
        @style.background({ :linear_gradient => { :color => [ "#FFFFFF", "#FFFFFF" ] } }),
        @style.font({ :size => "30px", :family => "arial", :style => "normal" }),
        @style.text({ :color => "#49c0f0", :align => "left" }),
        [ "width: 70%" ],
      ]),
      stylesheet( ".question_button_select:hover", [
        @style.background({ :linear_gradient => { :color => [ "#49c0f0", "#49c0f0" ] } }),
        @style.text({ :color => "#FFFFFF" }),
      ]),
      stylesheet( ".question_button_selected", [
        @style.border({ :border => "1px solid #228b22", :radius => "3px" }),
        @style.background({ :linear_gradient => { :color => [ "#FFFFFF", "#FFFFFF" ] } }),
        @style.font({ :size => "30px", :family => "arial", :style => "normal" }),
        @style.text({ :color => "#00cc66", :align => "left" }),
        [ "width: 70%" ],
      ]),
      stylesheet( ".question_button_selected:hover", [
        @style.background({ :linear_gradient => { :color => [ "#00cc66", "#00cc66" ] } }),
        @style.text({ :color => "#FFFFFF" }),
      ]),
      stylesheet( ".question_bar", [
        [ "height: 100%; list-style-type: none; padding: 0; margin: 0" ],
      ]),
      stylesheet( ".question_bar_select_finish", [
        @style.border({ :border => "1px solid #49c0f0", :radius => "3px" }),
        @style.background({ :linear_gradient => { :color => [ "#49c0f0", "#49c0f0" ] } }),
        [ "height: 100%" ],
      ]),
      stylesheet( ".question_bar_selected_finish", [
        @style.border({ :border => "1px solid #00cc66", :radius => "3px" }),
        @style.background({ :linear_gradient => { :color => [ "#00cc66", "#00cc66" ] } }),
        [ "height: 100%" ],
      ]),
    ]
    
    super.concat([{
      :content => contents.join( "\n" )
    }])
  end
end
