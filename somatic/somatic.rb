require 'json'
require 'rest-client'
require 'active_support/core_ext'
require 'optparse'
if ENV['SOMATIC_API_KEY'].blank?
  puts "SOMATIC_API_KEY not set"
  exit
end
puts "SOMATIC_ENV:#{ENV['SOMATIC_ENV']}"
#from http://stackoverflow.com/questions/3047007/flattening-hash-into-string-in-ruby
class Hash

  #from http://stackoverflow.com/questions/9786264/all-possible-combinations-from-a-hash-of-arrays-in-ruby
  def self.product_hash(hsh)
    attrs   = hsh.values
    keys    = hsh.keys
    product = attrs[0].product(*attrs[1..-1])
    product.map{ |p| Hash[keys.zip p] }
  end
end
module Somatic
  class Data
    def self.api_url
      if ENV['SOMATIC_ENV'] == "production"
        "http://www.somatic.io/"
      else
        "http://localhost:3000/"
      end
    end
    def self.parse_opts!
      #this is for bvlc googlenet's architect,  we want every image to print
      @@options ||= {}
      OptionParser.new do |opts|
        opts.banner = "Usage: example.rb [options]"

        opts.on("-t", "--tags [X]", "tags to add") do |v|
          @@options[:tags] = v
        end
        opts.on("-i", "--model_id [X]", "model id") do |v|
          @@options[:model_id] = v
        end
        opts.on("-f", "--file_or_dir [X]", "file or dir") do |v|
          @@options[:file_or_dir] = v
        end
        opts.on("-c", "--iteration_count [X]", "interation count") do |v|
          @@options[:iteration_count] = v
        end
        opts.on("-e", "--email [X]", "email to send to") do |v|
          @@options[:email] = v
        end
      end.parse!
      @@options
    end
    def self.options
      @@options
    end
      
  end

    class Model
      def make_api_call params,tags=nil
        api_url = "#{Somatic::Data.api_url}/api/v1/models/async_query"
        raise "model_id not set" if @model_id.blank?
        @tags ||= tags || Time.now.to_f
        #tag_line = tags.present? ? " -F tag=#{@tags} " : " -F tag=#{Time.now.to_f} "
        tag_line = " -F tag=#{@tags} "
        cmd = "curl --fail -X POST -F api_key=#{ENV['SOMATIC_API_KEY']} "
        params.each do | k,v| 
          if v.kind_of?(String) && ::File.exists?(v) #hack,only files here
            line = "-F #{k}=@#{v} "
            cmd += line
          elsif v.present?
            cmd += "-F #{k}=#{v} "
          end
        end
        cmd += " -F id=#{@model_id} #{tag_line} #{api_url}"
        puts "running:#{cmd}"
        `#{cmd}`
      end

    def initialize opts = {}
      @opts = opts
      @api_call_count = 0
      @model_id = opts[:model_id]
    end
    def explore_inference_param_permutations opts={}
      steps =  opts[:steps] || 4
      permutations = {}
      params = modelfile['Inference']['tuning'] rescue []
      params.each do |key,v|
        if v['min'] && v['max']
          current_step = min = v['min']
          max = v['max']
          step = (max - min) / steps
          step = 1 if step == 0

          temp = []
          each_step = []
          while current_step <= max
            temp << "#{key} #{current_step}"
            current_step += step
            each_step << current_step
          end
          permutations[key]=each_step
        elsif v['combos']
          elements = v['combos'].split(',')
          groups = []
          (1..elements.size).each do |length|
            groups += elements.combination(length).to_a.collect{|x| x.join(',') }
          end
          permutations[key] = groups.shuffle[0...2]
        elsif v['choices']
          permutations[key] = v['choices'].split(',') 
        end
      end
      puts permutations
      puts 'DDDDD'
      Hash.product_hash(permutations)
    end
    def inference_param_permutations opts={}
      steps =  4
      permutations = []
      params = modelfile['Inference']['tuning'] rescue []
      params.each do |key,v|
        current_step = min = v['min']
        max = v['max']
        step = (max - min) / steps
        step = 1 if step == 0

        temp = []
        while current_step <= max
          temp << "#{key} #{current_step}"
          current_step += step
        end

        if permutations.empty?
          permutations = temp
        else
          permutations = permutations.product temp
        end
      end
      permutations.collect do |x|
        params = x.join(' ')
        hash = {}
        kvs = params.split
        kvs.each_with_index do |x,i|
          if i % 2 == 0 && kvs[i+1]
            hash[x] = kvs[i+1]
          end
        end
        default_inference_params.merge(opts).merge(hash)
      end
    end
    def online_modelfile
      api_info
    end
    def local_modelfile
    end
    def modelfile
      online_modelfile
    end
    def default_inference_params
      defaults = {}.with_indifferent_access
      modelfile['Inference']['parameters'].each do |k,v|
        if v['default']
          defaults[k] = v['default']
        end
      end
      defaults
    end
  end

end
