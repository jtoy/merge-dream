load './somatic/somatic.rb'
require 'optparse'
require 'mechanize'
#this is for bvlc googlenet's architect,  we want every image to print
options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: example.rb [options]"

  opts.on("-t", "--tags [X]", "tags to add") do |v|
    options[:tags] = v
  end
  opts.on("-i", "--model_id [X]", "model id") do |v|
    options[:model_id] = v
  end
  opts.on("-f", "--file_or_dir [X]", "file or dir") do |v|
    options[:file_or_dir] = v
  end
  opts.on("-c", "--classtoshow [X]", "interation count") do |v|
    options[:classtoshow] = v
  end
end.parse!

id = options[:model_id] || "pE4A9yk0"
somatic_model = Somatic::Model.new({model_id:id})

images = nil
first_arg = options[:file_or_dir]
if Dir.exists?(first_arg)
  images = Dir.glob("#{first_arg}/*").select{|x|  File.exists?(x) && !Dir.exists?(x)}.collect{|x| File.expand_path(x) }
elsif File.exists?(first_arg)
  images = [first_arg]
else
  puts "no data for processing supplied"
  raise
end
classes = options[:classtoshow].split(',')

images.each do |image|
  filepath = image
  filename_count = 1
  classes.each do |class_value|

    params = {"--image":filepath,"--class-to-show":class_value}
    puts "params: #{params}"
    example_id=somatic_model.make_api_call params,options[:tags]
    puts example_id
    agent = Mechanize.new;
    sleep(70)
    page = agent.get('http://www.somatic.io/examples/' + example_id)
    page.links_with(:href =>  /(.*)processed/).each do |link|
      puts link.href
      filename = "#{filename_count}.jpg"
      agent.get(link.href).save filename
    end
    filename_count = filename_count + 1
  end
  size=`identify -format "%wx%h" 1.jpg`
  `convert -page +0-15 -size #{size} gradient: \
        -sigmoidal-contrast 5,50% -contrast-stretch 0 \
        -set option:distort:viewport #{size}-90-45 \
        +distort SRT 115 +repage \
        1.jpg -extent #{size} +swap \
        2.jpg +swap \
        -gravity East -composite  #{options[:classtoshow]}.jpg`
  `rm 1.jpg`
  `rm 2.jpg`
end
puts "Done!"
