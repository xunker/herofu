%w[rubygems sinatra activerecord yaml erb].each do |r|
  require r
end

require 'models'

get '/' do
  'default page'
end

get %r{/([\w\/]+)} do
    "Hello, #{params[:captures].first}!"
end

