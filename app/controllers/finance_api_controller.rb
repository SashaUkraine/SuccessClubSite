class FinanceApiController < ApplicationController
  
  skip_before_filter :verify_authenticity_token
  before_action :prepare_input_data, except: [:payment_form, :output]
  before_action :prepera_params_output, only: [:output]


  require 'digest'
  require "base64"
  require 'json'

  def responce_status
    if !skip_validation
      unless @responce_data[:success]
        head 444
        return
      end
      update_user_balance
    end
    puts "#{params[:id]} balance after function :" + Wallet.find_by(user_id: @responce_data[:user_id]).main_balance.to_s + "\n"
    head 200
  end

  def success
    flash[:notice] = "Поздравляем! Ваш баланс пополнен на #{@responce_data[:amount]}$"
	  redirect_to_home_after_payment(true)
  end

  def error
    flash[:error] = "Счет не пополнен"
  	redirect_to_home_after_payment(false)
  end

  def payment_form

    render inline: get_payment_form

  end
  def output

    if current_user.enough? params['amount'].to_f
      
      if(make_withdrawal)
        flash[:notice] = "Поздравляем! Ваш зарос на вывод средств принят."
      else
        flash[:notice] = "Приносим свои извинения, произошла ошибка, обратитесь в техподдержку."
      end

    else
      flash[:notice] = "Приносим свои извинения, на вашем счету недостаточно средств."
    end
    redirect_to home_path

  end

  private
  def payment_exists payment_code
    Payment.find_by(code: payment_code)
  end
  def prepera_params_output
    redirect_to home_path, notice: "Введите все параменты пожалуйста." if params['amount'].blank? || params['user_account'].blank?
  end
  def get_amount_with_commision(amount, service_name)
    commitions = {
      'advcash' => 0,
      'perfectmoney' => 2,
      'nixmoney' => 0.5
    }
    amount.to_f - amount.to_f * commitions[service_name].to_f / 100
  end
  def make_withdrawal
    Withdrawal.create(
        user_id: current_user.id,
        amount: get_amount_with_commision(params['amount'], params['system_output']),
        method: params['system_output'],
        user_account: params['user_account']
    ) && current_user.take_money(params['amount'])
  end
  def method_name
    
  end

  def skip_validation
    ["success", "error"].include?(params['action'])
  end
  def update_user_balance

    Payment.create(
      amount: @responce_data[:amount].to_f,
      to_user_id: @responce_data[:user_id],
      from: params['id'][0, 7],
      to: 'user',
      method: params['id'],
      code: @responce_data[:payment_code]
    )
    User.find(@responce_data[:user_id]).give_money(@responce_data[:amount].to_f)
  end

  def prepare_input_data

    send("adapte_#{params[:id]}_data")

  end

  def adapte_liqpay_data

    head 400 if (params['data'].blank? || params['signature'].blank?)# && Rails.env.production? #render :status => 400

    liqpay = Liqpay::Liqpay.new
    sign = liqpay.str_to_sign(
     liqpay.instance_values['private_key']  +
     params['data'] +
     liqpay.instance_values['private_key']
    )
    liqpay_data = JSON.parse(Base64.decode64(params['data']))

    head 422 unless params['signature'] == sign #render :status => 422
    puts 'liqpay_status:' + liqpay_data['status']
    status_of_payment = (liqpay_data['status'] == "success") || (liqpay_data['status'] == "wait_accept")

    make_responce_data(liqpay_data['customer'], liqpay_data['amount'], liqpay_data['currency'], status_of_payment)

  end

  def adapte_nixmoney_data
    head 422 if params['V2_HASH'] != make_hash_for_ckeck_from(params_for_check(ENV['NIX_MONEY_PASS']), 'MD5') && !skip_validation#render :status => 422
    make_responce_data(params['user_id'], params['PAYMENT_AMOUNT'], params['PAYMENT_UNITS'], true)
  end

  def adapte_perfectmoney_data
    Rails.logger.debug "params.to_json:"
    Rails.logger.debug params.to_json
    head 422 if params['V2_HASH'] != make_hash_for_ckeck_from(params_for_check(ENV['PERFECT_MONEY_PASS']), 'MD5')&& !skip_validation#render :status => 422
    make_responce_data(params['user_id'], params['PAYMENT_AMOUNT'], params['PAYMENT_UNITS'], true)
  end

  def adapte_advcash_data

    head 400 if params['ac_hash'].blank? && !skip_validation#render :status => 400

    status_params = [params['ac_transfer']]
    status_params.push(params['ac_start_date'])
    status_params.push(params['ac_sci_name'])
    status_params.push(params['ac_src_wallet'])
    status_params.push(params['ac_dest_wallet'])
    status_params.push(params['ac_order_id'])
    status_params.push(params['ac_amount'])
    status_params.push(params['ac_merchant_currency'])
    status_params.push(ENV['ADV_CASH_PASS'])

    sign = make_hash_for_ckeck_from(status_params, 'SHA256')
    # puts "Params\n" +  params.to_json + "\n"
    #puts "Sign\n" +  sign + "\n"
    unless skip_validation
      head 422 if  params['ac_hash'] != sign || payment_exists(params['ac_order_id'])#||
    end
    puts 'advcash_status:' + params['ac_transaction_status']
    status_of_payment = ["COMPLETED"].include?(params['ac_transaction_status'])
    make_responce_data(params['user_id'], params['ac_amount'], params['ac_merchant_currency'], status_of_payment, params['ac_order_id'])
  end

  def make_responce_data(customer, amount ,currency, status, payment_code = '')

    head 400 if customer.blank? || amount.blank? || currency.blank? || status.blank? && Rails.env.production? && !skip_validation#render :status => 400
    @responce_data = {
        :user_id => customer,
        :amount => amount,
        :currency => currency,
        :success => status,
        :payment_code => payment_code
    }
    puts "#{params[:id]} responce values : " + @responce_data.to_json + "\n"
  end

  def get_payment_form
    case params['service_name']
    when 'liqpay'
      liqpay = Liqpay.new
      liqpay.cnb_form({
      :version      => '3',
      :action       => "pay",
      :amount       => params['amount'],
      :currency     => "USD",
      :description  => 'No desc yet',
      :customer     => current_user.id.to_s,
      :server_url   => "http://improf.club/finance_api/responce_status/liqpay",
      :result_url   => "http://improf.club/finance_api/success/liqpay",
      :language     => "ru"
      }).html_safe
    when 'advcash'
      if (params['order_id'].blank? || params['amount'].blank?)
        'some params are missing'
      else
        string_to_sign = ["club.mlm30@gmail.com"]
        string_to_sign.push("Professionals Club")
        string_to_sign.push(params['amount'])
        string_to_sign.push('USD')
        string_to_sign.push(ENV['ADV_CASH_PASS'])
        string_to_sign.push(params['order_id'])

        make_hash_for_ckeck_from(string_to_sign,'SHA256')
      end
    else
      'there is no such servise on the system'
    end
  end

  def redirect_to_home_after_payment(status)
  	redirect_to home_path, payment_status: status, payment_amount: @responce_data['amount']
  end

  def make_hash_for_ckeck_from( values, mode )

    # puts '(Digest::' + mode + ".new).digest('" + values.join(":") + "')"
    # exec('(Digest::' + mode + ".new).digest('" + values.join(":") + "')")#.upcase
    # puts "Encoded suppsosedly what's needed " + (Digest::SHA256.new).hexdigest("235f9d0b-b48f-462c-9949-621c4930490c:2012-06-23 12:30:00:My Shop:U123456789012:U210987654321:123456:123.45:USD:P@ssw0rd")
    begin
      # puts "\n #{params[:id]} String to encode " + values.join(":")
    rescue
      # puts "\n #{params[:id]} Password to encode " + values
      
    end
    values = [values] if values.is_a? String 

    case mode
    when 'MD5'
      # puts "\n #{params[:id]} Encoded " + (Digest::MD5.new).hexdigest(values.join(":")).upcase + "\n"
      (Digest::MD5.new).hexdigest(values.join(":")).upcase
    when 'SHA256'
      # puts "\n #{params[:id]} Encoded " + (Digest::SHA256.new).hexdigest(values.join(":")) + "\n"
      (Digest::SHA256.new).hexdigest(values.join(":"))
    else
      "error in hash generation"
    end

  end

  def params_for_check(password)
  	#Important to preserve the order.
    params_available = !params['PAYER_ACCOUNT'].nil?
  	if params_available
	  	status_params = [params['PAYMENT_ID']]
	  	status_params.push(params['PAYEE_ACCOUNT'])
	  	status_params.push(params['PAYMENT_AMOUNT'])
	  	status_params.push(params['PAYMENT_UNITS'])
	  	status_params.push(params['PAYMENT_BATCH_NUM'])
	  	status_params.push(params['PAYER_ACCOUNT'])
	  	status_params.push(make_hash_for_ckeck_from(password, 'MD5'))
	  	status_params.push(params['TIMESTAMPGMT'])
	  	status_params
	  else
      []
    end
  end
end
