class BusinessController < ApplicationController
  before_action :authenticate_user!
  before_action :pro_user, except: [:show]
  before_action :prepare_params, only: [:activate, :update_settings]

  def business
    @scopes = %w(my all recent problem)
    unless @scopes.include? params[:type]
      params[:type] = 'all'
      params[:action] = 'index'
    end

    user_busi = current_user.businesses

    @businesses = params[:type] == 'my' ? user_busi : eval('Business.' + params[:type]).where.not(id: user_busi.ids)
    @businesses = @businesses.newest_first.paginate_by params[:page]
  end

  def show
  	@business = Business.find(params[:id])
    @comments = @business.comments.order(created_at: :desc)
    @parent = current_user.find_active_parent(@business)
    @link = @business.get_link @parent
    @has_parent = !@parent.nil?
  end

  def activate
    if current_user.role.name == 'user'
      flash[:error] = "Для активации бизнеса вам необходимо \nподключить статус 'Партнер'\nНа странице профиля"
      redirect_to business_scope_path 'all'
      return
    end
	  @business = Business.find(params[:id])
	  parent_link = PartnerLink.find_or_create_by(
	  	user_id: current_user.id,
	  	use_for: @business.name
	  )
	  parent_link.update_attribute(:link, ref_link)
	  UserBusiness.find_or_create_by(
	    user_id: current_user.id,
      business_id: @business.id
    ).update_attributes(partner_link_id: parent_link.id, block_reg: params['block_reg'])

	  flash[:notice] = 'Поздавляем, бизнес успешно активирован'
	  redirect_to "/landings/?business_id=#{@business.id}"
  end

  def deactivate
  	settings = UserBusiness.find_by(user_id: current_user.id, business_id: params[:id])
  	unless settings
  	  flash[:error] = 'Не удалось найти..'
  	  redirect_to business_scope_path 'all'
  	  return
  	end
  	unless settings.destroy
  	  flash[:error] = 'Что то пошло не так, обратитесь в тех поддержку'
      redirect_to business_scope_path 'all'
  	  return
  	end
  	flash[:notice] = 'Вы успешно деактивировали бизнес'
  	redirect_to business_scope_path 'my'
  end

  def settings
  	@settings = UserBusiness.find_by(
  	  user_id: current_user.id, business_id: params[:id]
  	)
  	@partner_link = @settings.partner_link
  	@business = Business.find(params[:id])
  end

  def update_settings
  	@settings = UserBusiness.find_by(user_id: current_user.id, business_id: params[:id])
  	@settings.update_attribute(:block_reg, params[:settings][:block_reg])
  	@settings.partner_link.update_attribute(:link, ref_link)
  	flash[:notice] = "Изменения сохранены"
  	redirect_to business_scope_path 'my'
  end

  def comment
    @business = Business.find(params[:id])
    @comment = @business.comments.new(
      user: current_user,
      content: params[:content],
      rate: params[:mark] )
    if @comment.save then
      flash[:notice] = "Комментарий отправлен"
    else
      flash[:notice] = "Нельзя отправить пустой комментарий"
    end
    redirect_to business_path(@business)
  end

  def instructions
    render "instruction", layout: false
  end

  private
  def pro_user
  	redirect_to '/' unless user_has_rights
  end

  def prepare_params
  	if (params[:link].blank?) || params[:id].blank?
  	# if params[:ref_link].blank?
  	  flash[:error] = "Часть данных отсутствует.\nВведите свою реферральную ссылку, пожалуйста"
  	  redirect_to business_scope_path 'all'
  	end
  	# params.require(:ref_link)
  end

  def ref_link
  	ref_link_str = params[:link] || params[:partner_link][:link]
  	if redex_business? and not ref_link_str.start_with?(Business.find(params[:id]).link_template)
  	  ref_link_str = Business.find(params[:id]).link_template + ref_link_str
  	else
  	  ref_link_str
  	end
    ref_link_str
  end

  def redex_business?
  	params[:id] == "1" #Redex business_id
  end
end
