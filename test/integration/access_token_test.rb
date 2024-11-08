require "test_helper"

class AccessTokenTest < ActionDispatch::IntegrationTest
  def setup
    @user = active_user
    @encode = UserAuth::AccessToken.new(user_id: @user.id)
    @lifetime = UserAuth.access_token_lifetime
  end

  # 共通メソッド
  test 'auth_token_methods' do
    # 初期設定値は想定通りか
    assert_equal 'HS256', @encode.send(:algorithm)
    assert_equal @encode.send(:secret_key), @encode.send(:decode_key)
    assert_equal :sub, @encode.send(:user_claim)
    assert_equal({ typ: 'JWT', alg: 'HS256' }, @encode.send(:header_fields))

    # user_idはnilの場合、暗号メソッドは nilを返しているか
    user_id = nil
    assert_nil @encode.send(:encrypt_for, user_id)

    # user_idがnilの場合、複合メソッドはnilを返しているか
    usr_id = nil
    assert_nil @encode.send(:decrypt_for, user_id)

    # user_idが不正な場合、複合メソッドはnilを返しているか
    user_id = "aaaaaa"
    assert_nil @encode.send(:decrypt_for, user_id)
  end

  # デコード検証
  test 'decode_token' do
    decode = UserAuth::AccessToken.new(token: @encode.token)
    payload = decode.payload

    # デコードユーザーは一致しているか
    token_user = decode.entity_for_user
    assert_equal @user, token_user

    # verify_claimsは想定通りか
    verify_claims = decode.send(:verify_claims)
    assert_equal UserAuth.token_issuer, verify_claims[:iss]
    assert_equal UserAuth.token_audience, verify_claims[:aud]
    assert_equal UserAuth.token_signature_algorithm, verify_claims[:algorithm]
    assert verify_claims[:verify_expiration]
    assert verify_claims[:verify_iss]
    assert verify_claims[:verify_aud]
    assert_not verify_claims[:sub]
    assert_not verify_claims[:verify_sub]

    # 有効期限内はエラーを吐いていないか
    travel_to (@lifetime.from_now - 1.second) do
      assert UserAuth::AccessToken.new(token: @encode.token)
    end

    # 有効期限後トークンはエラーを吐いているか
    travel_to (@lifetime.from_now) do
      assert_raises JWT::ExpiredSignature do
        UserAuth::AccessToken.new(token: @encode.token)
      end
    end

    # トークンが書き換えられた場合エラーを吐いているか
    invalid_token = @encode.token + 'a'
    assert_raises JWT::VerificationError do
      UserAuth::AccessToken.new(token: invalid_token)
    end

    # issuerが改ざんされたtokenはエラーを吐いているか
    invalid_token = UserAuth::AccessToken.new(payload: { iss: 'invalid' }).token
    assert_raises JWT::InvalidIssuerError do
      UserAuth::AccessToken.new(token: invalid_token)
    end

    # audienceが改竄されたtokenはエラーを吐いているか
    invalid_token = UserAuth::AccessToken.new(payload: { aud: 'invalid' }).token
    assert_raises JWT::InvalidAudError do
      UserAuth::AccessToken.new(token: invalid_token)
    end
  end

  # デコードオプション
  test 'verify_claims' do
    # subオプションは有効か
    sub = @encode.user_id
    options = { sub: sub }
    decode = UserAuth::AccessToken.new(token: @encode.token, options: options)
    verify_claims = decode.send(:verify_claims)
    assert_equal sub, verify_claims[:sub]
    assert verify_claims[:verify_sub]

    # subオプションで有効なユーザーは返ってきているか
    token_user = decode.entity_for_user
    assert_equal @user, token_user

    # 不正なsubにはエラーを吐いているか
    options = { sub: 'invalid' }
    assert_raises JWT::InvalidSubError do
      UserAuth::AccessToken.new(token: @encode.token, options: options)
    end
  end

  # not activeユーザーの挙動
  test 'not_active_user' do
    not_active = User.create(name: 'a', email: 'a@a.a', password: 'password')
    assert_not not_active.activated
    encode_token = UserAuth::AccessToken.new(user_id: not_active.id).token

    # アクティブではないユーザーも取得できるか
    decode_token_user = UserAuth::AccessToken.new(token: encode_token).entity_for_user

    assert_equal not_active, decode_token_user
  end
end
