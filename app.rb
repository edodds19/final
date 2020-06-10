# Set up for the application and database. DO NOT CHANGE. #############################
require "sinatra"                                                                     #
require "sinatra/reloader" if development?                                            #
require "sequel"                                                                      #
require "logger"                                                                      #
require "twilio-ruby"                                                                 #
require "geocoder"                                                                    #
require "bcrypt"                                                                      #
connection_string = ENV['DATABASE_URL'] || "sqlite://#{Dir.pwd}/development.sqlite3"  #
DB ||= Sequel.connect(connection_string)                                              #
DB.loggers << Logger.new($stdout) unless DB.loggers.size > 0                          #
def view(template); erb template.to_sym; end                                          #
use Rack::Session::Cookie, key: 'rack.session', path: '/', secret: 'secret'           #
before { puts; puts "--------------- NEW REQUEST ---------------"; puts }             #
after { puts; }                                                                       #
#######################################################################################

cocktails_table = DB.from(:cocktails)
guests_table = DB.from(:guests)
users_table = DB.from(:users)

# read your API credentials from environment variables
account_sid = ENV["TWILIO_ACCOUNT_SID"]
auth_token = ENV["TWILIO_AUTH_TOKEN"]

# set up a client to talk to the Twilio REST API
client = Twilio::REST::Client.new(account_sid, auth_token)

# send the SMS from your trial Twilio number to your verified non-Twilio number

before do
    # SELECT * FROM users WHERE id = session[:user_id]
    @current_user = users_table.where(:id => session[:user_id]).to_a[0]
    puts @current_user.inspect
end

# Home page (all cocktails)
get "/" do
    # before stuff runs
    @cocktails = cocktails_table.all

    results = Geocoder.search("1590 Elmwood Ave, Evanston, IL 60201")
    @lat_long = results.first.coordinates.join(",")

    view "cocktails"
end

# Show a single cocktail
get "/cocktails/:id" do
    @users_table = users_table
    # SELECT * FROM cocktails WHERE id=:id
    @cocktail = cocktails_table.where(:id => params["id"]).to_a[0]
    # SELECT * FROM guests WHERE cocktails_id=:id
    @guests = guests_table.where(:cocktail_id => params["id"]).to_a
    # SELECT COUNT(*) FROM guests WHERE cocktail_id=:id AND going=1
    @count = guests_table.where(:cocktail_id => params["id"], :going => true).count
    view "cocktail"
end

# Form to create a new guest
get "/cocktails/:id/guests/new" do
    @cocktail = cocktails_table.where(:id => params["id"]).to_a[0]
    view "new_guest"
end

# Receiving end of new guest form
post "/cocktails/:id/guests/create" do
    guests_table.insert(:cocktail_id => params["id"],
                       :going => params["going"],
                       :user_id => @current_user[:id],
                       :special_requests => params["special_requests"])
    @cocktail = cocktails_table.where(:id => params["id"]).to_a[0]
    if session[:user_id] = @current_user[:id] 
    view "create_guest"
    else
        view "create_login"
    end
end

# Form to create a new user
get "/users/new" do
    view "new_user"
end

# Receiving end of new user form
post "/users/create" do
    puts params.inspect
    users_table.insert(:name => params["name"],
                       :email => params["email"],
                       :password => BCrypt::Password.create(params["password"]))
                       client.messages.create(
                        from: "+12029637855", 
                        to: "+19176999920",
                        body: "A new user has signed up for Centrum!")
    view "create_user"
end

# Form to login
get "/logins/new" do
    view "new_login"
end

# Receiving end of login form
post "/logins/create" do
    puts params
    email_entered = params["email"]
    password_entered = params["password"]
    # SELECT * FROM users WHERE email = email_entered
    user = users_table.where(:email => email_entered).to_a[0]
    if user
        puts user.inspect
        # test the password against the one in the users table
        if BCrypt::Password.new(user[:password]) == password_entered
            session[:user_id] = user[:id]
            view "create_login"
        else
            view "create_login_failed"
        end
    else 
        view "create_login_failed"
    end
end

# Logout
get "/logout" do
    session[:user_id] = nil
    view "logout"
end