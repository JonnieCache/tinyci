interactor :off

guard :rspec, cmd: "bundle exec rspec", all_after_pass: true, all_on_start: true do
  watch(%r{^lib\/tinyci\/(.+)\.rb$}) { |m| "spec/#{m[1]}_spec.rb" }
  watch(%r{spec\/support\/.+})       { "spec" }
  watch(%r{^spec\/.+_spec\.rb$})
end
