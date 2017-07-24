module RuCaptcha
  module ViewHelpers
    def rucaptcha_input_tag(opts = {})
      opts[:name]           = '_rucaptcha'
      opts[:type]           = 'text'
      opts[:autocorrect]    = 'off'
      opts[:autocapitalize] = 'off'
      opts[:pattern]        = '[0-9]*'
      opts[:maxlength]      = 5
      opts[:autocomplete]   = 'off'
      tag(:input, opts)
    end

    def rucaptcha_image_tag(opts = {})
      opts[:class] = opts[:class] || 'rucaptcha-image'
      opts[:id] = opts[:id] || 'rucaptcha_image'
      ru_captcha_url = opts.delete(:captcha_url) || ru_captcha.root_url
      %(<img src="#{ru_captcha_url}" #{opts.map { |k, v| "#{k}=\"#{v}\"" }.join(' ')} />).html_safe
    end

    def rucaptcha_regenerate_image_link(text, image_tag_id = 'rucaptcha_image', opts  = {})
      ru_captcha_url = opts.delete(:captcha_url) || ru_captcha.root_url
      onclick = "document.getElementById('#{image_tag_id}').src = '#{ru_captcha_url}?' + new Date().getTime();"
      opts = opts.merge(onclick: onclick)
      %(<a href="javascript:void(0)" #{opts.map { |k, v| "#{k}=\"#{v}\"" }.join(' ')}>#{text}</a>).html_safe
    end
  end
end
