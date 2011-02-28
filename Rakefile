require 'rake'
require 'spec'

require 'spec/rake/spectask'

desc "Run specs"
Spec::Rake::SpecTask.new do |t|
  spec_files = Rake::FileList["spec/**/*_spec.rb"]
  t.spec_files = spec_files
end

task :deploy do
  sh "git push origin master"
end

task :github do
  sh "git push github master"
end

task :default => [:spec]
