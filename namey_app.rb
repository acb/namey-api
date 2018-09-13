require 'sinatra'
require 'namey'
require 'json'

#set :protection, :except => [:json_csrf]
disable :protection

class Hash
  def symbolize_keys!
    keys.each do |key|
      self[(key.to_sym rescue key) || key] = delete(key)
    end
    self
  end
end
  
get '/' do
  erb :index
end
  
get '/name.?:format?' do
  @db =  Sequel.connect(ENV['DATABASE_URL'])
  @generator = Namey::Generator.new(@db)

  opts = {
    :frequency => :common
  }.merge(params.symbolize_keys!)

  if params[:with_surname] == "true"
    opts[:with_surname] = true
  else
    opts[:with_surname] = false
  end

  [:type, :frequency].each do |key|
    opts[key] = opts[key].to_sym if opts.has_key?(key)
  end

  opts.delete(:type) if ! [:male, :female, :surname].include?(opts[:type])
  
  count = (params.delete(:count) || 1).to_i
  count = 10 if count > 10
  
  names = 1.upto(count).collect do
    @generator.generate(opts)
  end.compact

  @db.disconnect

  if params[:format] == "json"
    content_type :json, 'charset' => 'utf-8'
    tmp = JSON.generate names
    if params[:callback]
      "#{params[:callback]}(#{tmp});"
    else
      tmp
    end
  else
    ["<ul>", names.collect { |n| "<li>#{n}</li>" }.join(" "), "</ul>"].join("")
  end
end 
