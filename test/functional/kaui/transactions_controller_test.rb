require 'test_helper'

class Kaui::TransactionsControllerTest < Kaui::FunctionalTestHelper

  test 'should get restful endpoint' do
    get :restful_show, :id => @payment.transactions[0].transaction_id
    assert_response :redirect
    expected_response_path = "/accounts/#{@payment.account_id}/payments/#{@payment.payment_id}"
    assert response_path.include?(expected_response_path), "#{response_path} is expected to contain #{expected_response_path}"
  end

  test 'should get new' do
    get :new,
        :account_id => @account.account_id,
        :payment_method_id => @payment_method.payment_method_id,
        :payment_id => @payment.payment_id,
        :amount => 12,
        :currency => 'USD',
        :transaction_type => 'CAPTURE'
    assert_response 200
    assert_equal get_value_from_input_field('account_id'), @account.account_id
    assert_equal get_value_from_input_field('payment_method_id'), @payment_method.payment_method_id
    assert has_input_field('transaction_transaction_id')


    get :new, :account_id => @account.account_id,
        :payment_method_id => @payment_method.payment_method_id, :transaction_id => @payment.transactions[0].transaction_id
    assert_response :success
    assert_equal get_value_from_input_field('account_id'), @account.account_id
    assert_equal get_value_from_input_field('payment_method_id'), @payment_method.payment_method_id
    assert_equal get_value_from_input_field('transaction_transaction_id'), @payment.transactions[0].transaction_id
    assert_equal get_value_from_input_field('transaction_payment_id'), @payment.payment_id
  end

  test 'should create new transaction' do
    payments = []
    %w(AUTHORIZE AUTHORIZE PURCHASE PURCHASE CREDIT).each do |transaction_type|
      post :create,
           :account_id => @account.account_id,
           :payment_method_id => @payment_method.payment_method_id,
           :transaction => {
               :payment_external_key => SecureRandom.uuid,
               :amount => 12,
               :currency => 'USD',
               :transaction_type => transaction_type
           }

      payments << created_payment_id
      assert_redirected_to account_payment_path(@account.account_id, payments[-1])
      assert_equal 'Transaction successfully created', flash[:notice]
    end

    %w(CAPTURE VOID REFUND CHARGEBACK).each do |transaction_type|
      payment_id = payments.shift
      post :create,
           :account_id => @account.account_id,
           :transaction => {
               :payment_id => payment_id,
               :amount => 12,
               :currency => 'USD',
               :transaction_type => transaction_type
           }
      assert_redirected_to account_payment_path(@account.account_id, payment_id)
      assert_equal 'Transaction successfully created', flash[:notice]
    end
  end

  test 'should fix transaction state' do
    parameters = {
      :account_id => @account.account_id,
      :transaction => {
        :payment_id => @payment.payment_id,
        :transaction_id => @payment.transactions[0].transaction_id,
        :status => 'PENDING'
      }
    }

    put :fix_transaction_state, parameters
    assert_response :redirect
    expected_response_path = "/accounts/#{@payment.account_id}/payments/#{@payment.payment_id}"
    assert_equal "Transaction successfully transitioned to #{parameters[:transaction][:status]}", flash[:notice]
    assert response_path.include?(expected_response_path), "#{response_path} is expected to contain #{expected_response_path}"
  end

  private

  def created_payment_id
    response.header['Location'].split('/')[-1]
  end
end
