#version = File.read('README.textile').scan(/^\*\s+([\d\.]+)/).flatten

Gem::Specification.new do |s|
  s.name     = "delayed_job"
  s.version  = "1.7.0"
  s.date     = "2008-11-28"
  s.summary  = "Database-backed asynchronous priority queue system -- Extracted from Shopify"
  s.email    = "tobi@leetsoft.com"
  s.homepage = "http://github.com/tobi/delayed_job/tree/master"
  s.description = "Delated_job (or DJ) encapsulates the common pattern of asynchronously executing longer tasks in the background. It is a direct extraction from Shopify where the job table is responsible for a multitude of core tasks."
  s.authors  = ["Tobias Lütke"]

  # s.bindir = "bin"
  # s.executables = ["delayed_job"]
  # s.default_executable = "delayed_job"

  s.has_rdoc = false
  s.rdoc_options = ["--main", "README.textile"]
  s.extra_rdoc_files = ["README.textile"]

  # run git ls-files to get an updated list
  s.files = %w[
    MIT-LICENSE
    README.textile
    delayed_job.gemspec
    init.rb
    lib/delayed/job.rb
    lib/delayed/message_sending.rb
    lib/delayed/performable_method.rb
    lib/delayed/worker.rb
    lib/delayed_job.rb
    tasks/jobs.rake
    tasks/tasks.rb
  ]
  s.test_files = %w[
    spec/database.rb
    spec/delayed_method_spec.rb
    spec/job_spec.rb
    spec/story_spec.rb
  ]
end
