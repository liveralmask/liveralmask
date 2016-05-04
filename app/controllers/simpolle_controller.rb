class SimpolleController < ApplicationController
  def create
    @question = Owrb::JSON.decode( param( "question", '{"title":"", "choices":{"0":"", "1":"", "2":"", "3":"", "4":""}}' ) )
    @question[ "time_limits" ] = {}
    7.times{|index|
      day = index + 1
      @question[ "time_limits" ][ "#{day}日後に投票終了" ] = day
    }
    @question[ "time_limit" ] = "1" if ! @question.key?( "time_limit" )
    
    @javascripts.push({
      :content => <<EOS
$(function(){
  $( "#question-edit" ).width( global.content.width );
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
    
    redirect_to "/simpolle/show/#{result[ :question_key ]}"
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
    
    @javascripts.push({
      :content => <<EOS
$(function(){
  $( "#question-preview" ).width( global.content.width );
})
EOS
    })
    
    self_question = SimpolleQuestion.find_by( account_id: @provider_account.account_id )
    if ! self_question.nil?
      @self_question = Owrb::JSON.decode( decode( self_question.question ) )
    end
  end
  
  def show
    @question_choice = -1
    begin
      @question_key = param( "question_key", "" )
      if @question_key.empty?
        question = SimpolleQuestion.find_by( account_id: @provider_account.account_id )
        @question_key = encode( question.id.to_s ) if ! question.nil?
      else
        question_id = decode( @question_key ).to_i
        question = SimpolleQuestion.find_by( id: question_id )
      end
      
      if ! question.nil?
        question_choice = SimpolleQuestionChoice.find_by( simpolle_question_id: question_id )
        @question_choice = question_choice.choice if ! question_choice.nil?
      end
    rescue => err
      question = nil
    end
    
    if ! question.nil?
      @question = Owrb::JSON.decode( decode( question.question ) )
      time_limit = time_limit( Time.at( @question[ "time_limit" ] ) )
      @time_limit = "#{time_limit[ :at ]}(#{time_limit[ :time ]})"
      @is_finished = time_limit[ :is_finished ]
      
      result = Owrb::JSON.decode( decode( question.result ) )
      result = nil if ( question.account_id != @provider_account.account_id ) && ! @is_finished
      if ! result.nil?
        total = result[ "choices" ].inject{|sum, value| sum + value}
        @question[ "choices" ].each_with_index{|text, i|
          num = result[ "choices" ][ i ]
          parcentage = ( 0 == total ) ? 0 : ( ( num.to_f / total ) * 100 ).to_i
          
          @question[ "choices" ][ i ] = "#{text}  #{parcentage}%(#{num})"
        }
      end
      
      @javascripts.push({
        :content => <<EOS
$(function(){
  $( "#question-show" ).width( global.content.width );
})
EOS
      })
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
    
    redirect_to "/simpolle/show/#{result[ :question_key ]}"
  end
  
protected
  def stylesheets
    contents = [
      stylesheet( "textarea.question_title", [
        @style.font({ :size => "30px" }),
        [ "width: 100%; resize:none" ],
      ]),
      stylesheet( "b.question_title", [
        @style.font({ :size => "30px" })
      ]),
      stylesheet( "input.question_choice", [
        @style.font({ :size => "30px" }),
        [ "width: 100%; margin: 10px 0" ],
      ]),
      stylesheet( "button.question_choice", [
        @style.font({ :size => "30px", :style => "normal" }),
        [ "width: 100%" ],
      ]),
      stylesheet( "select.question_time_limits", [
        @style.font({ :size => "20px" }),
        [ "width: 100%" ],
      ]),
      stylesheet( "b.question_time_limit", [
        @style.font({ :size => "20px" }),
        @style.text({ :color => "#FF0000" }),
      ]),
    ]
    
    super.concat([{
      :content => contents.join( "\n" )
    }])
  end
end
