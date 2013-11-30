=begin
/*

The MIT License (MIT)

Copyright (c) 2013 Zhussupov Zhassulan zhzhussupovkz@gmail.com

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

*/
=end

require 'net/http'
require 'net/https'
require 'json'
require 'openssl'

class Pechkin

  def initialize api_key= nil, login= nil, pass= nil
    raise ArgumentError.new('Не заданы обязательные параметры') if not api_key
    raise ArgumentError.new('Не заданы обязательные параметры') if not login
    raise ArgumentError.new('Не заданы обязательные параметры') if not pass
    @api_key, @login, @pass = api_key, login, pass
    @api_url = 'https://api.pechkin-mail.ru/'
  end

  #get data
  def get_data query=nil, options={}
    raise ArgumentError.new('Не заданы обязательные параметры') if not query.is_a? String
    auth = { 'username' => @login, 'password' => @pass, 'format' => 'json' }
    options = auth.merge(options)
    opts = URI.escape(options.collect{ |k,v| "#{k}=#{v}"}.join('&'))
    url = @api_url + '?method=' + query + '&' + opts
    uri = URI.parse url
    http = Net::HTTP.new uri.host, uri.port
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    req = Net::HTTP::Get.new uri.reuest_uri
    res = http.request req
    data = res.body
    if not data.is_a? String or not data.is_json?
      raise RuntimeError, "Сервер возвращает неверный формат данных."
    end
    result = JSON.parse data
    if result['msg']['err_code'] == '0'
      result['data']
    else
      get_error result['msg']['err_code']
    end
  end

  #post data
  def post_data query= nil, options= {}
    raise ArgumentError.new('Не заданы обязательные параметры') if not query.is_a? String
    auth = { 'username' => @login, 'password' => @pass, 'format' => 'json' }
    options = auth.merge(options)
    opts = URI.escape(options.collect{ |k,v| "#{k}=#{v}"}.join('&'))
    url = @api_url + '?method=' + query
    uri = URI.parse url
    http = Net::HTTP.new uri.host, uri.port
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    req = Net::HTTP::Post.new uri.request_uri
    req.set_form_data opts
    res = http.request req
    data = res.body
    if not data.is_a? String or not data.is_json?
      raise RuntimeError, "Сервер возвращает неверный формат данных."
    end
    result = JSON.parse data
    if result['msg']['err_code'] == '0'
      result['data']
    else
      get_error result['msg']['err_code']
    end
  end

  #get errors
  def get_error key
    errors = {
      '2' => 'Ошибка при добавлении в базу',
      '3' => 'Заданы не все необходимые параметры',
      '4' => 'Нет данных при выводе',
      '5' => 'У пользователя нет адресной базы с таким id',
      '6' => 'Некорректный email-адрес',
      '7' => 'Такой пользователь уже есть в этой адресной базе',
      '8' => 'Лимит по количеству активных подписчиков на тарифном плане клиента',
      '9' => 'Нет такого подписчика у клиента',
      '10' => 'Пользователь уже отписан',
      '11' => 'Нет данных для обновления подписчика',
      '12' => 'Не заданы элементы списка',
      '13' => 'Не задано время рассылки',
      '14' => 'Не задан заголовок письма',
      '15' => 'Не задано поле От Кого?',
      '16' => 'Не задан обратный адрес',
      '17' => 'Не задана ни html ни plain_text версия письма',
      '18' => 'Нет ссылки отписаться в тексте рассылки. Пример ссылки: отписаться',
      '19' => 'Нет ссылки отписаться в тексте рассылки',
      '20' => 'Задан недопустимый статус рассылки',
      '21' => 'Рассылка уже отправляется',
      '22' => 'У вас нет кампании с таким campaign_id',
      '23' => 'Нет такого поля для сортировки',
      '24' => 'Заданы недопустимые события для авторассылки',
      '25' => 'Загружаемый файл уже существует',
      '26' => 'Загружаемый файл больше 5 Мб',
      '27' => 'Файл не найден',
      '28' => 'Указанный шаблон не существует',
      '100' => 'Неверные данные для подключения API',
      '101' => 'Несуществующий метод API или указан некорректный метод API',
    }
    errors[key]
  end

  class String
    def serialize
      "s:#{self.size}:\"#{self}\";"
    end
  end

  class Array
    def serialize
      serialized = "a:#{self.size}:{"
      self.each_with_index do |e, i|
        serialized += "#{i.serialize}#{e.serialize}"
      end
      serialized + "}"
    end
  end

  class Hash
    def serialize
      serialized = "a:#{self.size}:{"
      self.each_with_index do |e, i|
        serialized += "#{i.serialize}#{e.serialize}"
      end
      serialized + "}"
    end
  end

  class Fixnum
    def serialize
      "i:#{self};"
    end
  end

  class Float
    def serialize
      "d:#{self};"
    end
  end

  #serialize hash
  def serialize hash
    serialized = "a:#{hash.size}:{"
    hash.each_pair do |k, e|
      serialized += "#{k.serialize}#{e.serialize}"
    end
    serialized + "}"
  end

  ################## Работа с Адресными Базами ###########################

  #lists.get - Получаем список баз пользователя
  #optional: list_id
  def lists_get list_id = ''
    if not list_id.empty?
      options = { 'list_id' => list_id }
    else
      options = {}
    end
    get_data 'lists.get', options
  end

  #lists.add - Добавляем адресную базу
  #required: name
  #optional: abuse_email, abuse_name, company...
  #http://pechkin-mail.ru/?page=api_details&method=lists.add
  def lists_add name = nil, options = {}
    raise ArgumentError.new('Не заданы обязательные параметры') if not name
    required = { 'name' => name }
    options = required.merge(options)
    send_data 'lists.add', options
  end

  #lists.update - Обновляем контактную информацию адресной базы
  #required: list_id
  #optional: name, abuse_email, abuse_name, company...
  #see: http://pechkin-mail.ru/?page=api_details&method=lists.update
  def lists_update list_id = nil, options = {}
    raise ArgumentError.new('Не заданы обязательные параметры') if not list_id
    list_id = { 'list_id' => list_id }
    options = list_id.merge(options)
    send_data 'lists.update', options
  end

  #lists.delete - Удаляем адресную базу и всех активных подписчиков в ней.
  #required: list_id
  def lists_delete list_id = nil
    raise ArgumentError.new('Не заданы обязательные параметры') if not list_id
    options = { 'list_id' => list_id }
    send_data 'lists.delete', options
  end

  #lists.get_members - Получаем подписчиков в адресной базе с возможность фильтра и регулировки выдачи.
  #required: list_id
  #optional: state, start, limit...
  #see: http://pechkin-mail.ru/?page=api_details&method=lists.get_members
  def lists_get_members list_id = nil, options = {}
    raise ArgumentError.new('Не заданы обязательные параметры') if not list_id
    required = { 'list_id' => list_id }
    options = required.merge(options)
    get_data 'lists.get_members', options
  end

  #lists.upload - Импорт подписчиков из файла
  #required: list_id, file, email
  #optional: merge_1, merge_2, type, update...
  #see: http://pechkin-mail.ru/?page=api_details&method=lists.upload
  def lists_upload list_id = nil, file = nil, email = nil, options = {}
    raise ArgumentError.new('Не заданы обязательные параметры') if not list_id || not file || not email
    required = { 'list_id' => list_id, 'file' => file, 'email' => email }
    options = required.merge(options)
    send_data 'lists.upload', options
  end

  #lists.add_member - Добавляем подписчика в базу
  #required: list_id, email
  #optional: merge_1, merge_2..., update...
  #see: http://pechkin-mail.ru/?page=api_details&method=lists.add_member
  def lists_add_member list_id = nil, email = nil, options = {}
    raise ArgumentError.new('Не заданы обязательные параметры') if not list_id || not email
    required = { 'list_id' => list_id, 'email' => email }
    options = required.merge(options)
    send_data 'lists.add_member', options
  end

  #lists.update_member - Редактируем подписчика в базе
  #required: member_id
  #optional: merge_1, merge_2...
  #see: http://pechkin-mail.ru/?page=api_details&method=lists.update_member
  def lists_update_member member_id = nil, options = {}
    raise ArgumentError.new('Не заданы обязательные параметры') if not member_id
    required = { 'member_id' => member_id }
    options = required.merge(options)
    send_data 'lists.update_member', options
  end

  #lists.delete_member - Удаляем подписчика из базы
  #required: member_id
  def lists_delete_member member_id = nil
    raise ArgumentError.new('Не заданы обязательные параметры') if not member_id
    options = { 'member_id' => member_id }
    send_data 'lists.delete_member', options
  end

  #lists.unsubscribe_member - Редактируем подписчика в базе
  #optional: member_id, email, list_id
  #see: http://pechkin-mail.ru/?page=api_details&method=lists.unsubscribe_member
  def lists_unsubscribe_member options = {}
    send_data 'lists.unsubscribe_member', options
  end

  #lists.move_member - Перемещаем подписчика в другую адресную базу.
  #required: member_id, list_id
  def lists_move_member member_id = nil, list_id = nil
    raise ArgumentError.new('Не заданы обязательные параметры') if not member_id || not list_id
    options = { 'member_id' => member_id, 'list_id' => list_id }
    send_data 'lists.move_member', options
  end

  #lists.copy_member - Копируем подписчика в другую адресную базу
  #required: member_id, list_id
  def lists_copy_member member_id = nil, list_id = nil
    raise ArgumentError.new('Не заданы обязательные параметры') if not member_id || not list_id
    options = { 'member_id' => member_id, 'list_id' => list_id }
    send_data 'lists.copy_member', options
  end

  #lists.add_merge - Добавить дополнительное поле в адресную базу
  #required: list_id, type
  #optional: choises, title, ...
  #see: http://pechkin-mail.ru/?page=api_details&method=lists.add_merge
  def lists_add_merge list_id = nil, type = nil, options = {}
    raise ArgumentError.new('Не заданы обязательные параметры') if not list_id || not type
    required = { 'list_id' => list_id, 'type' => type }
    options = required.merge(options)
    send_data 'lists.add_merge', options
  end

  #lists.update_merge - Обновить настройки дополнительного поля в адресной базе
  #required: list_id, merge_id
  #optional: choisesm title, ...
  #see: http://pechkin-mail.ru/?page=api_details&method=lists.update_merge
  def lists_update_merge list_id = nil, merge_id = nil, options = {}
    raise ArgumentError.new('Не заданы обязательные параметры') if not list_id || not merge_id
    required = { 'list_id' => list_id, 'merge_id' => merge_id }
    options = required.merge(options)
    send_data 'lists.update_merge', options
  end

  #lists.delete_merge - Удалить дополнительное поле из адресной базы
  #required: list_id, merge_id
  #see: http://pechkin-mail.ru/?page=api_details&method=lists.delete_merge
  def lists_delete_merge list_id = nil, merge_id = nil
    raise ArgumentError.new('Не заданы обязательные параметры') if not list_id || not merge_id
    options = { 'list_id' => list_id, 'merge_id' => merge_id }
    send_data 'lists.delete_merge', options
  end

  ##################### Работа с рассылками #####################

  #campaigns.get - Получаем список рассылок пользователя
  #optional: campaign_id, status, list_id, type
  #see: http://pechkin-mail.ru/?page=api_details&method=campaigns.get
  def campaigns_get options = {}
    get_data 'campaigns.get', options
  end

  #campaigns.create - Создаем рассылку
  #required: list_id
  #optional: name, subject, ...
  #see: http://pechkin-mail.ru/?page=api_details&method=campaigns.create
  def campaigns_create list_id = nil, options = {}
    raise ArgumentError.new('Не заданы обязательные параметры') if not list_id
    list_id = serialize(list_id);
    required = { 'list_id' => list_id }
    options = required.merge(options)
    send_data 'campaigns.create', options
  end

  #campaigns.create_auto - Создаем авторассылку
  #optional: list_id, name, subject
  #see: http://pechkin-mail.ru/?page=api_details&method=campaigns.create_auto
  def campaigns_create_auto options = {}
    options['list_id'] = serialize(options['list_id'])
    send_data 'campaigns.create_auto', options
  end

  #campaigns.update - Обновляем параметры рассылки
  #required: campaign_id
  #optional: list_id, name, subject, ...
  #see: http://pechkin-mail.ru/?page=api_details&method=campaigns.update
  def campaigns_update campaign_id = nil, options = {}
    raise ArgumentError.new('Не заданы обязательные параметры') if not campaign_id
    required = { 'campaign_id' => campaign_id }
    options['list_id'] = serialize(options['list_id'])
    options = required.merge(options)
    send_data 'campaigns.update', options
  end

  #campaigns.update_auto - Обновляем параметры авторассылки
  #required: campaign_id
  #optional: list_id, name, subject, ...
  #see: http://pechkin-mail.ru/?page=api_details&method=campaigns.update_auto
  def campaigns_update_auto campaign_id = nil, options = {}
    raise ArgumentError.new('Не заданы обязательные параметры') if not campaign_id
    required = { 'campaign_id' => campaign_id }
    options['list_id'] = serialize(options['list_id']
    options = required.merge(options)
    send_data 'campaigns.update_auto', options
  end

  #campaigns.delete - Удаляем рассылку
  #required: campaign_id
  #see: http://pechkin-mail.ru/?page=api_details&method=campaigns.delete
  def campaigns_delete campaign_id = nil
    raise ArgumentError.new('Не заданы обязательные параметры') if not campaign_id
    options = { 'campaign_id' => campaign_id }
    send_data 'campaigns.delete', options
  end

  #campaigns.attach - Прикрепляем файл
  #required: campaign_id, url
  #optional: name
  #see: http://pechkin-mail.ru/?page=api_details&method=campaigns.attach
  def campaigns_attach campaign_id =  nil, url = nil, options = {}
    raise ArgumentError.new('Не заданы обязательные параметры') if not campaign_id || not url
    raise.ArgumentError.new('Неверный формат URL') if not url.is_a? String
    required = { 'campaign_id' => campaign_id, 'url' => url }
    options = required.merge(options)
    send_data 'campaigns.attach', options
  end

  #campaigns.get_attachments - Получаем приложенные файлы
  #required: campaign_id
  #see: http://pechkin-mail.ru/?page=api_details&method=campaigns.get_attachments
  def campaigns_get_attachments campaign_id = nil, options = {}
    raise ArgumentError.new('Не заданы обязательные параметры') if not campaign_id
    required = { 'campaign_id' => campaign_id }
    options = required.merge(options)
    get_data 'campaigns.get_attachments', options
  end

  #campaigns.delete_attachments - Удаляем приложенный файл
  #required: campaign_id, id
  #see: http://pechkin-mail.ru/?page=api_details&method=campaigns.delete_attachments
  def campaigns_delete_attachments campaign_id = nil, id = nil, options = {}
    raise ArgumentError.new('Не заданы обязательные параметры') if not campaign_id || not id
    required = { 'campaign_id' => campaign_id, 'id' => id }
    options = required.merge(options)
    send_data 'campaigns.delete_attachments', options
  end

  #campaigns.get_templates - Получаем html шаблоны
  #optional: name, id
  #see: http://pechkin-mail.ru/?page=api_details&method=campaigns.get_templates
  def campaigns_get_templates options = {}
    get_data 'campaigns.get_templates', options
  end

  #campaigns.add_template - Добавляем html шаблон
  #required: name, template
  #see: http://pechkin-mail.ru/?page=api_details&method=campaigns.add_template
  def campaigns_add_template name = nil, template = nil
    raise ArgumentError.new('Не заданы обязательные параметры') if not name || not template
    options = { 'name' => name, 'template' => template }
    send_data 'campaigns.add_templates', options
  end

  #campaigns.delete_template - Удаляем html шаблон
  #required: id
  def campaigns_delete_template id = nil
    raise ArgumentError.new('Не заданы обязательные параметры') if not id
    options = { 'id' => id }
    send_data 'campaigns.delete_templates', options
  end

  #campaigns.force_auto - Принудительно вызываем срабатывание авторассылки (при этом она должна быть активна)
  #required: campaign_id, email
  #optional: delay
  #see: http://pechkin-mail.ru/?page=api_details&method=campaigns.force_auto
  def campaigns_force_auto campaign_id = nil, email = nil, options = {}
    raise ArgumentError.new('Не заданы обязательные параметры') if not campaign_id || not email
    options = required.merge(options)
    send_data 'campaigns.force_auto', options
  end

end
