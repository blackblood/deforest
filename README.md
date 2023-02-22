# Deforest
> 80% of the effects come from 20% of the causes - Pareto principle

Get insights into method call stats in production. Deforest tracks all your model method calls in production and presents method usage data segmented as most used (red), medium used (yellow) and least used (green).
![High usage method](https://user-images.githubusercontent.com/1737753/218310194-68913ce3-75b9-49c4-aead-ab5eaa5185c0.png)
![Medium usage method](https://user-images.githubusercontent.com/1737753/218310233-81951339-c364-4d85-92f8-da3dbb012c78.png)
![Low usage method](https://user-images.githubusercontent.com/1737753/218310273-a3a68516-bbe8-41e3-bbc2-2fbbf67d1511.png)

You can anaylze this data the next time you are refactoring some code and want to know the impact of your change. Or if it's bearly used you may even decide to get rid of that code or whatever else. Use your imagination!

# Setup
Mention `gem deforest` in your Gemfile or install using `gem install deforest`. Then run `bundle install`.

Once the gem is installed, run `rake deforest`. This will create an initializer file `deforest.rb` in config/initializer.

Next, run `rake deforest:install:migrations`, this will create a deforest_logs table which stores the method usage data.
run `rake db:migrate`

Finally, add `mount Deforest::Engine => '/deforest'` in your `routes.rb`

That's it, you are all set. Now deforest will start collecting data into a log file. For every method call the gem will write some stats to the `deforest.log` file and periodically will persist the log file data to the `deforest_logs` table. By default it writes to the table every 1 minute but you can override this by setting `config.write_logs_to_db_every` (takes a datetime object) in `config/initializer/deforest.rb` 

## Usage
To see method usage data goto `/deforest/files/dashboard`. By default data will be shown for models, however you can check data for your other directories using the "Directory" dropdown in the header.

![Dashboard](https://user-images.githubusercontent.com/1737753/220743618-befdee12-c861-4733-abdd-7ab92143c39c.png)

If you use VS Code, you can view usage stats by downloading the extension data by clicking on "Extension Data" link. Once the file is downloaded, place it in the root of your application folder. Open VScode, download the Deforest extension, then go to any file you want to view usage stats for and then press (cmd + shft + p) -> select "deforest" in the command pallete. Scroll through the file to see methods highlighted in (red|yellow|green). You can hover over the method names to see the actual call count.

![VS Code Extension](https://user-images.githubusercontent.com/1737753/220743043-3e3e9ba8-f8d6-4ad1-8790-6bdbcba274ee.png)

## Configuration
There are a few settings you can tweak in `config/initializers/deforest.rb`.

`write_logs_to_db_every`: Deforest will persist data from the log file to the DB every `write_logs_to_db_every`. Change this to `5.minutes` or `1.hour` or anything else, depending on your application workload.

`current_admin_method_name`: `/deforest` urls are restricted only to logged in admins. You need to tell Deforest how to access the current logged in admin user object. By default, it's set to `current_admin`

`track_dirs`: add or remove directories you want deforest to track. default: `["/app/models", "/app/controllers", "/app/helpers"]`

`render_source_on_browser`: (true|false) whether deforest should read your source files and render the usage data in browser. Deforest checks if admin is logged-in before rendering source code on the browser. However, if you are not comfortable with your source code being accessible from a browser, you can set this to false.

`most_used_percentile_threshold`: Percentile threshold to tell Deforest what methods should be considered most used.

`least_used_percentile_threshold`: Percentile threshold to tell Deforest what methods should be considered least used.

## Caveats
Deforest is not tested in a multi-threaded/multi-process setup. It may not work. Will be fixing it in future releases.

## Features in pipeline
~~VS Code extension so you can see the highlighted methods in your editor itself instead of reading code on the browser.~~ (DONE)
Sublime text extension so you can see the highlighted methods in your editor itself instead of reading code on the browser.

## Contributing
Feel free to dive in! Open an <a href="https://github.com/blackblood/deforest/issues">issue</a> or submit PRs.