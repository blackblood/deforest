# Deforest
Get insights into method call stats in production. This gem tracks all your model method calls in production and presents method usage data segmented as most called (red), medium used (yellow) and least used (green).

# Setup
Mention `gem deforest` in your Gemfile or install using `gem install deforest`. Then run `bundle install`.

Once the gem is installed, run `rake deforest`. This will create an initializer file `deforest.rb` in config/initializer.

Next, run `rake deforest:install:migrations`, this will create a deforest_logs table which stores the method usage data.

Finally, add `mount Deforest::Engine => '/deforest'` in your `routes.rb`

That's it, you are all set. Now deforest will start collecting data into a log file. For every method call the gem will write some stats to the `deforest.log` file and periodically will persist the log file data to the `deforest_logs` table. By default it writes to the table every 1 minute but you can override this by setting `config.write_logs_to_db_every` (takes a datetime object) in `config/initializer/deforest.rb` 

## Usage
To see method usage data goto `/deforest/files/dashboard`. 
To check usage data of all your models goto `/deforest/files`.