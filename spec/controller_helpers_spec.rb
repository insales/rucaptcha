require 'spec_helper'
require 'securerandom'

describe RuCaptcha do
  class CustomCookies < Hash
    def [] key
      value = super key
      value = value[:value] if value.is_a? Hash
      value
    end
  end
  class Simple < ActionController::Base
    def cookies
      @cookies ||= CustomCookies.new
    end

    def params
      @params ||= {}
    end

    def custom_session
      RuCaptcha.cache.read(self.rucaptcha_sesion_key_key)
    end

    def clean_custom_session
      RuCaptcha.cache.delete(self.rucaptcha_sesion_key_key)
    end
  end

  let(:simple) { Simple.new }

  describe '.rucaptcha_sesion_key_key' do
    it 'should work' do
      simple.generate_rucaptcha
      expect(simple.rucaptcha_sesion_key_key).to eq ['rucaptcha-session', simple.cookies[:c_id]].join(':')
    end
  end

  describe '.generate_rucaptcha' do
    it 'should work' do
      allow(RuCaptcha).to receive(:create).and_return(['abcde', 'fake image data'])
      expect(simple.generate_rucaptcha).to eq 'fake image data'
      expect(simple.custom_session[:code]).to eq('abcde')
    end
  end

  describe '.verify_rucaptcha?' do
    before { simple.generate_rucaptcha }

    context 'Nil of param' do
      it 'should work when params[:_rucaptcha] is nil' do
        simple.params[:_rucaptcha] = nil
        expect(simple.verify_rucaptcha?).to eq(false)
      end

      it 'should work when session[:_rucaptcha] is nil' do
        simple.clean_custom_session
        simple.params[:_rucaptcha] = 'Abcd'
        expect(simple.verify_rucaptcha?).to eq(false)
      end
    end

    context 'Correct chars in params' do
      it 'should work' do
        RuCaptcha.cache.write(simple.rucaptcha_sesion_key_key, {
          time: Time.now.to_i,
          code: 'abcd'
        })
        simple.params[:_rucaptcha] = 'Abcd'
        expect(simple.verify_rucaptcha?).to eq(true)
        expect(simple.custom_session).to eq nil

        RuCaptcha.cache.write(simple.rucaptcha_sesion_key_key, {
          time: Time.now.to_i,
          code: 'abcd'
        })
        simple.params[:_rucaptcha] = 'AbcD'
        expect(simple.verify_rucaptcha?).to eq(true)
      end

      it 'should work with alternative param' do
        RuCaptcha.cache.write(simple.rucaptcha_sesion_key_key, {
          time: Time.now.to_i,
          code: 'abcd'
        })
        param_name = :_captcha_solution
        simple.params[param_name] = 'Abcd'
        expect(simple.verify_rucaptcha?(nil, param_name: param_name)).to eq(true)
        expect(simple.custom_session).to eq nil

        RuCaptcha.cache.write(simple.rucaptcha_sesion_key_key, {
          time: Time.now.to_i,
          code: 'abcd'
        })
        simple.params[param_name] = 'AbcD'
        expect(simple.verify_rucaptcha?(nil, param_name: param_name)).to eq(true)
      end

      it 'should keep session when given :keep_session' do
        RuCaptcha.cache.write(simple.rucaptcha_sesion_key_key, {
          time: Time.now.to_i,
          code: 'abcd'
        })
        simple.params[:_rucaptcha] = 'abcd'
        expect(simple.verify_rucaptcha?(nil, keep_session: true)).to eq(true)
        expect(simple.custom_session).not_to eq nil
        expect(simple.verify_rucaptcha?).to eq(true)
        expect(simple.verify_rucaptcha?).to eq(false)
      end
    end

    context 'Incorrect chars' do
      it 'should work' do
        RuCaptcha.cache.write(simple.rucaptcha_sesion_key_key, {
          time: Time.now.to_i - 60,
          code: 'abcd'
        })
        simple.params[:_rucaptcha] = 'd123'
        expect(simple.verify_rucaptcha?).to eq(false)
        expect(simple.custom_session).to eq nil
      end
    end

    context 'Expires Session key' do
      it 'should work' do
        RuCaptcha.cache.write(simple.rucaptcha_sesion_key_key, {
          time: Time.now.to_i - 121,
          code: 'abcd'
        })
        simple.params[:_rucaptcha] = 'abcd'
        expect(simple.verify_rucaptcha?).to eq(false)
      end
    end
  end
end
