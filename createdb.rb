# Set up for the application and database. DO NOT CHANGE. #############################
require "sequel"                                                                      #
connection_string = ENV['DATABASE_URL'] || "sqlite://#{Dir.pwd}/development.sqlite3"  #
DB = Sequel.connect(connection_string)                                                #
#######################################################################################

# Database schema - this should reflect your domain model
DB.create_table! :cocktails do
  primary_key :id
  String :name
  String :description, text: true
  String :base_spirit
  String :method
  String :glassware
end
DB.create_table! :guests do
  primary_key :id
  foreign_key :cocktail_id
  foreign_key :user_id
  Boolean :going
  String :name
  String :email
  String :special_requests, text: true
end
DB.create_table! :users do
  primary_key :id
  String :name
  String :email
  String :password
end

# Insert initial (seed) data
cocktails_table = DB.from(:cocktails)

cocktails_table.insert(name: "Old Fashioned", 
                    description: "A true classic that never goes out of style.",
                    base_spirit: "Whiskey",
                    method: "Stirred",
                    glassware: "Rocks glass")

cocktails_table.insert(name: "Piña Colada", 
                    description: "The ultimate beach cocktail.",
                    base_spirit: "Rum",
                    method: "Blended",
                    glassware: "Hurricane glass")                    

cocktails_table.insert(name: "Martini", 
                    description: "A favorite of James Bond and others.",
                    base_spirit: "Gin",
                    method: "Stirred",
                    glassware: "Coupe")