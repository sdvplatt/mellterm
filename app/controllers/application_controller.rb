# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all
  helper_method :current_user_session, :current_user
  protect_from_forgery
  filter_parameter_logging :password, :password_confirmation
  before_filter :store_location, :setup_search
  layout 'indicator'
  
  rescue_from ActionController::RoutingError, :with => :not_found
  rescue_from ActionController::UnknownAction, :with => :not_found
  rescue_from ActiveRecord::RecordNotFound, :with => :not_found
  def not_found
    flash[:error] = "Page not found." 
    redirect_to root_path
  end
  
  # this search will be for global
  # DO NOT REMOVE From here.
  def setup_search
    @search = Translation.search(params[:search])
  end
  
  # Check for iphone/ipod devices, Nokia, Android
  def is_iphone_request?
    request.user_agent.downcase =~ /(mobile\/.+safari)|(iphone)|(ipod)|(blackberry)|(symbian)|(series60)|(android)|(smartphone)|(wap)|(mobile)/
  end

  def set_iphone_format
    if params[:desktop]
      session[:mobile] = nil
    end
    if is_iphone_request? or params[:mobile] or session[:mobile]
      session[:desktop] = nil
      session[:mobile] = true
      request.format = :iphone
    end
  end
    
  def initialize
    @start_time = Time.now.usec
  end
  
  def logged_in?
    !current_user.nil?
  end

  def authorized?
    logged_in? && current_user.admin?
  end

  def authorized_only
    redirect_to new_user_session_path unless authorized?
  end

  ##################
  # LOCALE METHODS #
  ##################

  def default_language
    "en"
  end
  
  # retrieve the language from the session store, 
  # otherwise set to default of pt-BR
  def get_locale_from_session
    if (session && session[:language])
      lang = session[:language]
    else
      lang = default_language
    end
    lang
  end

  # overwrite session language if params[:language] is given and fixate it
  # params[:session] only accepts 'en' or 'th' (English or Thai)
  # otherwise get from user profile
  def get_locale
    if (params[:language] && params[:language].to_s.match(/en|gb|de/))
      logger.debug "* Lang from headers : #{extract_locale_from_accept_language_header}"
      logger.debug "* session[:language] was: '#{session[:language]}'"
      session[:language] = params[:language]
    elsif RAILS_ENV == "test"
      session[:language] = "en"
    else
      session[:language] = get_locale_from_session
    end
    set_locale
  end

  def set_locale
    if session[:language]
      set_locale_to(session[:language])
    else
      lang = extract_locale_from_accept_language_header
      set_locale_to(default_language)
    end
  end

  def set_locale_to(lang)
    logger.debug "* Accept-Language: #{request.env['HTTP_ACCEPT_LANGUAGE']}"
    I18n.locale = lang
    logger.debug "* Locale set to '#{I18n.locale}'"
    logger.debug "* session[:language] is '#{session[:language]}'"
  end



  private
    def current_user_session
      return @current_user_session if defined?(@current_user_session)
      @current_user_session = UserSession.find
    end

    def current_user
      return @current_user if defined?(@current_user)
      @current_user = current_user_session && current_user_session.record
    end

    def require_user
      unless current_user
        store_location
        flash[:notice] = "You must be logged in to access this page"
        redirect_to new_user_session_url
        return false
      end
    end
    
    def require_admin
      unless current_user && current_user.admin?
        store_location
        flash[:notice] = "You must be logged in to access this page"
        redirect_to new_user_session_url
        return false
      end
    end

    def require_no_user
      if current_user
        store_location
        flash[:notice] = "You must be logged out to access this page"
        redirect_to root_path
        return false
      end
    end

    def store_location
      if params[:return_to]
        session[:return_to] = params[:return_to]
      else
        session[:return_to] = request.request_uri
      end
    end

    def redirect_back_or_default(default)
      redirect_to(session[:return_to] || default)
      session[:return_to] = nil
    end

end
