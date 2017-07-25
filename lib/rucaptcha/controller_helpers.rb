module RuCaptcha
  module ControllerHelpers
    extend ActiveSupport::Concern

    included do
      helper_method :verify_rucaptcha?
    end

    # session key of rucaptcha
    def rucaptcha_sesion_key_key
      session_id = session.respond_to?(:id) ? session.id : session[:session_id] || request.session_options[:id]
      ['rucaptcha-session', session_id].join(':')
    end

    # Generate a new Captcha
    def generate_rucaptcha
      res = RuCaptcha.generate()
      session_val = {
        code: res[0],
        time: Time.now.to_i
      }
      logger.info "#{'!' * 10} rucaptcha_key: #{rucaptcha_sesion_key_key}"
      RuCaptcha.cache.write(rucaptcha_sesion_key_key, session_val, expires_in: RuCaptcha.config.expires_in)
      res[1]
    end

    # Verify captcha code
    #
    # params:
    # resource - [optional] a ActiveModel object, if given will add validation error message to object.
    # :keep_session - if true, RuCaptcha will not delete the captcha code session.
    #
    # exmaples:
    #
    #   verify_rucaptcha?
    #   verify_rucaptcha?(user, keep_session: true)
    #   verify_rucaptcha?(nil, keep_session: true)
    #
    def verify_rucaptcha?(resource = nil, opts = {})
      # Make sure params have captcha
      param_name = opts[:param_name] || :_rucaptcha
      captcha = (params[param_name] || '').downcase.strip
      verify_rucaptcha_value?(captcha, resource, opts)
    end

    def verify_rucaptcha_value?(captcha, resource = nil, opts = {})
      store_info = RuCaptcha.cache.read(rucaptcha_sesion_key_key)
      # make sure move used key
      RuCaptcha.cache.delete(rucaptcha_sesion_key_key) unless opts[:keep_session]

      # Make sure session exist
      if store_info.blank?
        return add_rucaptcha_validation_error resource, opts
      end

      # Make sure not expire
      if (Time.now.to_i - store_info[:time]) > RuCaptcha.config.expires_in
        return add_rucaptcha_validation_error resource, opts
      end

      # Make sure params have captcha
      if captcha.blank?
        return add_rucaptcha_validation_error resource, opts, :empty
      end

      if captcha != store_info[:code]
        return add_rucaptcha_validation_error resource, opts
      end

      true
    end


    private

    def add_rucaptcha_validation_error resource, opts, error = :invalid
      return false if resource.nil? || !resource.respond_to?(:errors)
      error_field = opts[:error_field] || :base
      resource.errors.add(error_field, error)
      false
    end
  end
end
