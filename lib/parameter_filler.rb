require 'yaml'

class ParameterFiller

  attr_reader :config_files
  attr_reader :verbose
  attr_reader :interactive

  def initialize(files_list, verbose, interactive)
    @config_files = files_list
    @verbose = verbose
    @interactive = interactive
  end

  def fill_file_list
    @config_files.each do |file_name|
      if verbose
        puts 'Filling ' + file_name + '...'
      end
      fill_file file_name
    end
  end

  def fill_file(file_name)
    dist_file_name = file_name + '.dist'
    setup_files(file_name, dist_file_name)
    config_data = load_yaml_file file_name
    dist_data = load_yaml_file dist_file_name
    config_data = fill_parameters(config_data, dist_data)
    File.write(file_name, config_data.to_yaml)
  end

  def load_yaml_file(file_name)
    begin
      data = YAML.load_file(file_name)
      unless data
        data = {}
      end
    rescue Exception => e
      raise ArgumentError, 'Invalid YAML in config file ' + file_name unless data
    end
    data
  end

  def setup_files(file_name, dist_file_name)
    raise ArgumentError, 'Dist file not found for ' + file_name unless File.file?(dist_file_name)
    unless File.file?(file_name)
      File.write(file_name, '')
    end
    return
  end

  def fill_parameters(data, dist_data)
    data ||= {}
    dist_data.each do |key, value|
      unless data.has_key?(key) || dist_data[key].is_a?(Hash)
        data[key] = ask_for_param(key, value)
      end
      if dist_data[key].is_a?(Hash)
        unless data.has_key?(key)
          data[key] = {}
        end
        data[key] = fill_parameters(data[key], dist_data[key])
      end
    end
    data
  end

  def ask_for_param(key, default)
    return default unless interactive
    print "Key \"#{key}\" (default: #{default}): "
    param = gets.chomp
    if param.empty? || !interactive
      param = default
    else
      param = YAML.load(param)
    end
    param
  end
end

