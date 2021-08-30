require 'rubygems'
require 'sinatra'
#require 'sinatra/cross_origin'

require 'namey'
require 'json'

disable :protection

class Hash
  def symbolize_keys!
    keys.each do |key|
      self[(key.to_sym rescue key) || key] = delete(key)
    end
    self
  end
end

set :allow_origin, "*"
set :allow_methods, "GET,HEAD,POST"
set :allow_headers, "content-type,if-modified-since"
set :expose_headers, "location,link"

$generator = Namey::Generator.new


# configure do
#   enable :cross_origin
# end
# before do
#   response.headers['Access-Control-Allow-Origin'] = '*'
# end

get '/' do
  erb :index
end
  
get '/name.?:format?' do
  opts = {
    :frequency => :common
  }.merge(params.to_h.symbolize_keys!)

  opts[:with_surname] = (params[:with_surname] == true || params[:with_surname] == "true")

  [:type, :frequency].each do |key|
    opts[key] = opts[key].to_sym if opts.has_key?(key)
  end

  opts.delete(:type) if ! [:male, :female, :surname].include?(opts[:type])
  
  count = (params.delete(:count) || 1).to_i
  count = 10 if count > 10

  names = 1.upto(count).collect do
    $generator.generate(opts)
  end.compact

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
