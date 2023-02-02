# Deforest
> 80% of the effects come from 20% of the causes - Pareto principle

Get insights into method call stats in production. Deforest tracks all your model method calls in production and presents method usage data segmented as most used (red), medium used (yellow) and least used (green).

You can anaylze this data the next time you are refactoring some code and want to know the impact of your change. Or if it's bearly used you may even decide to get rid of that code or whatever else. Use your imagination!

# Setup
Mention `gem deforest` in your Gemfile or install using `gem install deforest`. Then run `bundle install`.

Once the gem is installed, run `rake deforest`. This will create an initializer file `deforest.rb` in config/initializer.

Next, run `rake deforest:install:migrations`, this will create a deforest_logs table which stores the method usage data.

Finally, add `mount Deforest::Engine => '/deforest'` in your `routes.rb`

That's it, you are all set. Now deforest will start collecting data into a log file. For every method call the gem will write some stats to the `deforest.log` file and periodically will persist the log file data to the `deforest_logs` table. By default it writes to the table every 1 minute but you can override this by setting `config.write_logs_to_db_every` (takes a datetime object) in `config/initializer/deforest.rb` 

## Usage
To see method usage data goto `/deforest/files/dashboard`. 
To check usage data of all your models goto `/deforest/files`.

## Configuration
There are a few settings you can tweak in `config/initializers/deforest.rb`.

`write_logs_to_db_every_mins`: Deforest will persist data from the log file to the DB every `write_logs_to_db_every_mins`. Change this to `5.minutes` or `1.hour` or anything else, depending on your application workload.

`current_admin_method_name`: `/deforest` urls are restricted only to logged in admins. You need to tell Deforest how to access the current logged in admin user object. By default, it's set to `current_admin`

`most_used_percentile_threshold`: Percentile threshold to tell Deforest what methods should be considered most used.

`least_used_percentile_threshold`: Percentile threshold to tell Deforest what methods should be considered least used.