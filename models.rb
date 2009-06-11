class Storage < ActiveRecord::Base
end

def use_main_app_database
  db = File.dirname(__FILE__) + "/database.yml"
  database_config = YAML.load(ERB.new(IO.read(db)).result)
  env = "development"
  (database_config[env]).symbolize_keys
end

ActiveRecord::Base.establish_connection(use_main_app_database)