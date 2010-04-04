require 'rake'
require 'spec'

require 'spec/rake/spectask'

spec_files = Rake::FileList["spec/**/*_spec.rb"]

desc "Run specs"
Spec::Rake::SpecTask.new do |t|
  t.spec_files = spec_files
end

task :deploy do
  sh "git push heroku master"
end

task :github do
  sh "git push origin master"
end

task :default => [:spec]
