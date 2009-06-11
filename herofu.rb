
%w[rubygems sinatra activerecord yaml erb].each { |r| require r }

class StoredFile < ActiveRecord::Base
end

def use_main_app_database
  db = File.dirname(__FILE__) + "/database.yml"
  database_config = YAML.load(ERB.new(IO.read(db)).result)
  env = "development"
  (database_config[env]).symbolize_keys
end

ActiveRecord::Base.establish_connection(use_main_app_database)

get '/' do
 # look for a file called 'index.html'
end

get '/admin' do
  if params['password'] == 'sh1sh2' && params['username'] = 'admin'
    @files = StoredFile.find(:all, :order => 'id')
    erb :admin, :layout => :admin_layout
  else
    erb :admin_login, :layout => :admin_layout
  end  
end

post '/admin' do
  if params['password'] == 'sh1sh2' && params['username'] = 'admin'
    StoredFile.create(
      :filename => params[:filename],
      :content => params[:uploaded_data][:tempfile].read,
      :mime_type => params[:uploaded_data][:type]
    )
    redirect "/admin?password=#{params['password']}&username=#{params['username']}"
  end
end

get "*" do |filename|
  file = StoredFile.find_by_filename(filename)
  file.content
end

__END__
@@ admin_layout
<html>
  <head>
    <title>
      Admin
    </title>
  </head>
  <body>
    <% if params['msg'] %><div><%= params['msg'] %></div><% end %>
    <div>
      <%= yield %>
    </div>
  </body>
</html>

@@ admin_login
<form method="get">
  Username: <input type="text" name="username" size="10"><br />
  Password: <input type="password" name="password" size="10"><br />
  <br />
  <input type="submit" value="Login">
</form>

@@ admin
<div>
  <ul><%= @files.size %> files are stored.
    <% @files.each do |file| %>
    <li><%= file.filename %></li>
    <% end %>
  </ul>
</div>
<div>
  <form accept-charset="utf-8" enctype="multipart/form-data" method="post">
    Filename (path included from /) where the file will be accessable on the web:<br />
    <input type="text" name="filename"><br />
    <input type="file" name="uploaded_data"/><br />
    <input type="submit" value="Upload">
  </form>
</div>
