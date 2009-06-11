
%w[rubygems sinatra activerecord yaml erb].each { |r| require r }

class StoredFile < ActiveRecord::Base
end

def use_main_app_database
  db = File.dirname(__FILE__) + "/config/database.yml"
  database_config = YAML.load(ERB.new(IO.read(db)).result)
  env = ENV['VENDOR'] == 'apple' ? 'development' : 'production'
  (database_config[env]).symbolize_keys
end

def serve_file(filename)
  file = StoredFile.find_by_filename(filename)
  if file.nil?
    not_found "404 NOT FOUND"
  else
    content_type file.mime_type, :charset => 'utf-8'
    file.content
  end
end

def credentials_pass?
  params['password'] == 'sh1sh2' && params['username'] = 'admin'
end

def url_creds
  "username=#{params['username']}&password=#{params['password']}"
end

def post_creds
  "<input type='hidden' name='username' value='#{params['username']}'><input type='hidden' name='password' value='#{params['password']}'>"
end

def human_size(bytes)
  bytes = bytes.to_i
  bytes > 1024 ? "#{(bytes/1024).to_i} kbytes" : "#{bytes} bytes"
end

ActiveRecord::Base.establish_connection(use_main_app_database)

get '/' do
  serve_file('/index.html')
end

get '/admin/edit/:id' do
  if credentials_pass? && StoredFile.exists?(:id => params[:id])
    @file = StoredFile.find(params[:id])
    erb :admin_edit, :layout => :admin_layout
  else
    redirect "/admin?#{url_creds}"
  end
end

post '/admin/edit/:id' do
  if credentials_pass? && StoredFile.exists?(:id => params[:id])
    @file = StoredFile.find(params[:id])
    filename = params[:filename]
    if filename.size > 0
      filename = '/' + filename unless filename.slice(0,1) == '/'
      @file.update_attributes(:filename => filename)
    end
  end
  redirect "/admin/edit/#{params[:id]}?#{url_creds}"
end

get '/admin/delete/:id' do
  if credentials_pass? && StoredFile.exists?(:id => params[:id])
    StoredFile.delete(StoredFile.find(params[:id]).id)
  end
  redirect "/admin?#{url_creds}"
end

get '/admin' do
  if credentials_pass?
    @files = StoredFile.find(:all, :order => 'filename')
    erb :admin, :layout => :admin_layout
  else
    erb :admin_login, :layout => :admin_layout
  end  
end

post '/admin' do
  if credentials_pass? && params[:uploaded_data].size > 0
    filename = params[:filename].size>0 ? params[:filename] : params[:uploaded_data][:filename]
    filename = '/' + filename unless filename.slice(0,1) == '/'
    StoredFile.create(
      :filename => filename,
      :content => params[:uploaded_data][:tempfile].read,
      :mime_type => params[:uploaded_data][:type]
    )
    redirect "/admin?#{url_creds}"
  end
end

get "*" do |filename|
  serve_file(filename)
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

@@ admin_edit
<div>
  <div>
    Filename: <%= @file.filename %><br />
    File Size: <%= human_size(@file.content.size) %><br />
    Uploaded: <%= @file.created_at %>
  </div>
  <div>
    Change file name and path:
    <form method="post">
      <input type="text" name="filename" value="<%= @file.filename %>" size=50><br />
      <input type="submit" value="Change">
    </form>
  </div>
  <div>
    <a href="/admin?<%= url_creds %>">&lt;&lt; back</a>
  </div>
</div>
@@ admin
<div>
  <ul><%= @files.size %> files are stored.
    <%- bytes_total = 0 %>
    <% @files.each do |file| %>
      <%- bytes_total += file.content.size %>
    <li>
      <a href="<%= file.filename %>" target="_blank"><%= file.filename %></a> (<%= human_size(file.content.size) %>) --- <i><a href="/admin/edit/<%= file.id %>?<%= url_creds %>">edit</a></i> --- <i><a href="/admin/delete/<%= file.id %>?<%= url_creds %>" onClick="if (confirm('Are you sure?')) { return true; } else { return false; }">delete</a></i><br />
    </li>
    <% end %>
  </ul>
  <div><%= human_size(bytes_total) %> total</div>
</div>
<div style="margin-10px; border: 1px solid grey; padding:5px;">
  <div>Upload a file</div>
  <form accept-charset="utf-8" enctype="multipart/form-data" method="post">
    <input type="file" name="uploaded_data"/><br />
    <br />
    Optional manual filename ("/full/path.ext") where the file will be accessable on the web:<br />
    <input type="text" name="filename"><br />
    <br />
    <input type="submit" value="Upload">
  </form>
</div>
