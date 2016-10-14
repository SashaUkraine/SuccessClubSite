module ApplicationHelper
    
    def business_link
      
      link = (user_has_rights ? 'href="' + business_index_path + '"' : '')
      htrml_classes = "menu-item " + is_active_controller('instruments/*').to_s + (user_has_rights ? "" : " disabled")      
      raw(
        "<a #{link} class='#{htrml_classes}'>" + 
        '<i class="fa fa-bank"></i>' + 
        ( user_has_rights ? '' : '<span class="dis-popup">Временно недоступно</span>') + 
        '<span class="full-menu">Бизнес</span>'
        )
    end
    def get_view_mode(type)
      unless session[:menu_bar_view_mode].blank?
        if session[:menu_bar_view_mode] == 'minimized'
          reversed_menu_view_mode type
        else
          default_menu_view_mode type
        end
      else
        default_menu_view_mode type
      end
    end
    def is_active_controller(controller_name)
        params[:controller] == controller_name ? "active" : nil
    end

    def is_active_action(action_name)
        params[:action] == action_name ? "active" : nil
    end

    def get_avatar(user, params = {})
      url = user.avatar_url
      url = 'no_avatar.png' if user.avatar_url.nil?
      image_tag(url, params)
    end

    def get_trasfer_money_form(servise)

     form = content_tag(:div, class: 'form-group') do
       form_tag servise['action'], method: 'POST', id: servise['name'] do |f|
          #fields = button_tag("Pay with #{servise['name']}")
          fields = ''
          servise['fields'].each { |key, value|  fields << hidden_field_tag(key, value)}
          fields.html_safe
        end
      end
      form.html_safe
    end
    private

    def default_menu_view_mode type
      if type == 'menu'
        'minimized'
      else
        'full'
      end
    end
    def reversed_menu_view_mode type
      if type == 'menu'
        'full'
      else
        'minimized'
      end
    end
end
