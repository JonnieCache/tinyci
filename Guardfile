# frozen_string_literal: true

interactor :off

guard :rspec, cmd: 'bundle exec rspec', all_after_pass: true, all_on_start: true do
  watch(%r{^lib\/tinyci\/(.+)\.rb$}) { |m| "spec/#{m[1]}_spec.rb" }
  watch(%r{spec\/support\/.+})       { 'spec' }
  ignore(%r{spec\/support\/repos})
  watch(%r{^spec\/.+_spec\.rb$})
end
