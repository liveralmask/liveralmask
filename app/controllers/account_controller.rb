class AccountController < ApplicationController
  def auth
    account_id = @provider_account.nil? ? 0 : @provider_account.id
    redirect_to "/auth/#{params[ :provider ]}?account_id=#{account_id}&dst_url=#{@dst_url}"
  end
  
  def auth_callback
    account_id = param( "account_id", "0" ).to_i
    auth = request.env[ "omniauth.auth" ]
    provider = auth[ "provider" ]
    uid = auth[ "uid" ]
    info = {
      :icon => auth[ "info" ][ "image" ],
      :name => {
        :user    => auth[ "info" ][ "nickname" ],
        :display => auth[ "info" ][ "name" ],
      }
    }
    access_token = {
      :token  => auth[ "credentials" ][ "token" ],
      :secret => auth[ "credentials" ][ "secret" ],
    }
    provider_uid = "#{provider}:#{uid}"
    
    provider_account = ProviderAccount.find_by( uid: provider_uid )
    account_id = provider_account.account_id if ! provider_account.nil?
    account = Account.find_by( id: account_id )
    
    result = transaction{
      if account.nil?
        account = Account.new
        account.save!
      end
      
      if provider_account.nil?
        provider_account = ProviderAccount.new
        provider_account.uid = provider_uid
        provider_account.account_id = account.id
        provider_account.login_key = generate_login_key
      end
      
      cipher = cipher( provider_account.login_key, account.id )
      provider_account.info         = encrypt( cipher, Owrb::JSON.encode( info ) )
      provider_account.access_token = encrypt( cipher, Owrb::JSON.encode( access_token ) )
      provider_account.save!
      
      cookie.set( :login_key, provider_account.login_key )
    }
    redirect_to @dst_url
  end
  
protected
  def check_login_account
  end
  
  def generate_login_key( count = 5 )
    now = Time.now.to_i
    random = Random.new( now + Random.rand( 0xFFFFFFFF ) )
    keys = [ now ]
    count.times{
      keys.push Random.new( random.rand( 0xFFFFFFFF ) ).rand( 0xFFFFFFFF )
    }
    [ random.rand( 0xFFFFFFFF ).to_s( 16 ), Owrb::Data.hash( keys.join( "_" ) ), random.rand( 0xFFFFFFFF ).to_s( 16 ) ].join( "" )
  end
  
  def cipher( login_key, account_id )
    cipher = Owrb::Data.cipher
    cipher.key_iv( login_key, "01" * ( ( account_id % 10 ) + 1 ) )
    cipher
  end
  
  def encrypt( cipher, data )
    encode( cipher.encrypt( data ) )
  end
  
  def decrypt( cipher, data )
    decode( cipher.decrypt( data ) )
  end
end
