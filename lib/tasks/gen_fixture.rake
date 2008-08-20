# Credit for most of this goes to Rob Bevan (robbevan.com)
namespace :db do
  namespace :fixtures do
  desc "Generate a fixture from the provided table"
  task :gen_one => :environment do
    table_name = ARGV[1]
    if table_name.nil?
      puts "need a table name"
      exit
    end
    sql = "SELECT * FROM %s" 
    ActiveRecord::Base.establish_connection
      i = "000"
      File.open("#{RAILS_ROOT}/test/fixtures/#{table_name}.yml", 'w') do |file|
      data = ActiveRecord::Base.connection.select_all(sql % table_name)
      file.write data.inject({}) { |hash, record|
      hash["#{table_name}_#{i.succ!}"] = record
      hash
    }.to_yaml
    end
    end
  end
end
