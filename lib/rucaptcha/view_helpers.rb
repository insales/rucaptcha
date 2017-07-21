module RuCaptcha
  module ViewHelpers
    def rucaptcha_input_tag(opts = {})
      opts[:name]           = '_rucaptcha'
      opts[:type]           = 'text'
      opts[:autocorrect]    = 'off'
      opts[:autocapitalize] = 'off'
      opts[:pattern]        = '[a-zA-Z]*'
      opts[:maxlength]      = 5
      opts[:autocomplete]   = 'off'
      tag(:input, opts)
    end

    def rucaptcha_image_tag(opts = {})
      opts[:class] = opts[:class] || 'rucaptcha-image'
      opts[:id] = opts[:id] || 'rucaptcha_image'
      ru_captcha_url = opts.delete(:captcha_url) || ru_captcha.root_url
      image_tag(ru_captcha_url, opts)
    end

    def rucaptcha_regenerate_image_link(text, image_tag_id = 'rucaptcha_image', opts  = {})
      ru_captcha_url = opts.delete(:captcha_url) || ru_captcha.root_url
      onclick = "document.getElementById('#{image_tag_id}').src = '#{ru_captcha_url}?' + new Date().getTime();"
      link_to text, 'javascript:void(0)', opts.merge(onclick: onclick)
    end
  end
end
