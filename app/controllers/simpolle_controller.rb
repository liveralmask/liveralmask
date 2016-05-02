class SimpolleController < ApplicationController
  def create
    @question = Owrb::JSON.decode( param( "question", '{"title":"", "choices":{"0":"", "1":"", "2":"", "3":"", "4":""}}' ) )
    
    return if @question[ "title" ].empty?
    return if ! request.post?
    return if ! params.key?( "create" )
    
    question = {
      :title => @question[ "title" ],
      :choices => @question[ "choices" ].select{|key, value| ! value.empty?}.values,
    }
    return if question[ :choices ].empty?
    
    p question
    
    question_key = encode( 0.to_s )
    redirect_to "/simpolle/show/#{question_key}"
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
      }
    })
  end
  
  def show
    begin
      question_id = decode( param( "question_key", "" ) ).to_i
      @question = SimpolleQuestion.find_by( id: question_id )
      @question_choice = @question.nil? ? nil : SimpolleQuestionChoice.find_by( question_id: @question.id )
    rescue => err
      @question = nil
      @question_choice = nil
    end
    
    @question_key = encode( @question.id ) if ! @question.nil?
  end
end
