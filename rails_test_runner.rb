require 'optimist'

class RailsTestRunner
  attr_accessor :test_mode,
                :command,
                :runs

  def run_test
    success_count = 0

    runs.times do |counter|
      space_print "RUN : #{counter + 1}"
      success = system command
      success_count += 1 if success
    end

    space_print "Test passed #{success_count} out of #{runs} times"
  end

  private

  def initialize(test_mode)
    self.test_mode = test_mode
    generate_command
  end

  def space_print(text)
    puts
    puts text
    puts
  end

  def generate_command
    env = Optimist.options do
      opt :file, 'Test file', type: :string, short: '-f'
      opt :browser, 'chrome or firefox', type: :string, short: '-b'
      opt :headless, 'true or false', type: :string, short: '-h'
      opt :type, 'model, integration....', type: :string, short: '-t'
      opt :no_apc, 'No Assessts Precompile', type: :string, short: '-n'
      opt :mobile, 'Run For Mobile', type: :string, short: '-m'
      opt :runs, 'Run for number of time', type: :int, short: '-r'
      opt :workers, 'Number of parallel workers(only for rails mode)', type: :string, short: '-w'
    end

    test_runner = "bin/#{test_mode}"
    rails_env = 'RAILS_ENV=test'
    file = browser = headless = mobile = workers = nil
    self.runs = 1
    test_type = 'test'
    test_type += ":#{env[:type]}" unless env[:type].nil?
    browser = "BROWSER=#{env[:browser]}" unless env[:browser].nil?
    headless = "HEADLESS=#{env[:headless]}" unless env[:headless].nil?
    mobile = "MOBILE=#{env[:mobile]}" unless env[:mobile].nil?
    unless env[:file].nil?
      file = if test_mode == 'rails'
               "'#{env[:file]}'"
             else
               "TEST='#{env[:file]}'"
             end
    end
    workers = "PARALLEL_WORKERS=#{env[:workers]}" unless env[:workers].nil?
    self.runs = env[:runs] unless env[:runs].nil?

    self.command = [
      test_runner,
      test_type,
      file,
      rails_env,
      browser,
      headless,
      mobile,
      workers
    ].reject(&:nil?).join(' ')

    if env[:no_apc] == 'true'
      space_print 'Skipping Assets Precompile'
    else
      space_print 'Precompiling assets'
      precompile_command = "#{test_runner} #{rails_env} assets:precompile"
      space_print "Precompile command : #{precompile_command}"
      system precompile_command
      space_print 'Precompile Sucess'
    end

    space_print "Test command : #{command}"
  end
end
