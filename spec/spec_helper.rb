require 'vimrunner'
require 'vimrunner/rspec'

Vimrunner::RSpec.configure do |config|
  #  Set to false to use an instance per test (slower, but can be easier
  #  to manage).
  config.reuse_server = false

  # Decide how to start a Vim instance. In this block, an instance should be
  # spawned and set up with anything project-specific.
  config.start_vim do
    vim = Vimrunner.start

    # Load the plugin
    plugin_path = File.expand_path('../..', __FILE__)
    vim.add_plugin(plugin_path, 'plugin/heresy.vim')

    # The returned value is the Client available in the tests.
    vim
  end
end

RSpec.configure do |config|
  config.before :each do
    # Default to setting the filetype to shell to enable
    # code-like behaviour.
    @ext = 'sh'
  end
end

def write_file_content(string, ext = 'sh')
  @file = "file.#{ext}"
  string = normalize_string_indent(string)
  File.open(@file, 'w') { |f| f.write(string) }
  vim.edit @file
end

def load_file_content
  vim.write
  IO.read(@file).strip
end

def type(string)
  string.scan(/<.*?>|./).each do |key|
    if key =~ /<.*>/
      vim.feedkeys "\\#{key}"
    else
      vim.feedkeys key
    end
  end
end

def initial(string)
  @vim_options.each { |x| vim.command(x) } if @vim_options
  write_file_content(string, @ext)
end

def final(string)
  expected = normalize_string_indent(string)
  expect(load_file_content).to eq expected
end

def use_extension(ext)
  @ext = ext
end
