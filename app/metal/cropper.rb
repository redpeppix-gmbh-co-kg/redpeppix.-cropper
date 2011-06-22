# Allow the metal piece to run in isolation
require File.expand_path('../../../config/environment',  __FILE__) unless defined?(Rails)

class Cropper
  class << self
    def call(env)
      if env["PATH_INFO"] =~ /^\/crop/
        request = Rack::Request.new(env)
        pix = Pix.find(request.params["id"].to_i) || raise(ActiveRecord::RecordNotFound)

        tmp_path = "#{Rails.root}/tmp/crops/#{pix.id}.tmp.jpg"
        final_path = "#{Rails.root}/tmp/crops/#{pix.id}.jpg"

        coords = pix.coords.split(",")
        padding = 10
        x_coords = []
        y_coords = []
        coords.each_index do |x|
          x.even? ? x_coords << coords[x].to_i : y_coords << coords[x].to_i
        end
      
        left   = (x_coords.sort.first-padding) < 0 ? 0 : x_coords.sort.first-padding
        top    = (y_coords.sort.first-padding) < 0 ? 0 : y_coords.sort.first-padding
        width  = x_coords.sort.last + padding - left
        height = y_coords.sort.last + padding - top

        # crop image using ImageMagick
        command = "convert #{pix.image.image_path} -crop #{width}x#{height}+#{left}+#{top}! #{tmp_path}"
        system(command)

        if true
          puts "########################################################"
          puts "Pix-Id = #{request.params["id"]}"
          puts "image-path = #{pix.image.image_path}"
          puts "x_coords = #{x_coords.join(", ")}"
          puts "y_coords = #{y_coords.join(", ")}"
          puts
          puts "top = #{top}"
          puts "left = #{left}"
          puts "right = #{x_coords.sort.last}"
          puts "bottom = #{y_coords.sort.last}"
          puts
          puts "width = #{width}"
          puts "height = #{height}"
          puts
          puts "command 1 = #{command}"
        end
      
        # put PIX-dot in center of the cropped image
        command = "composite -gravity center http://www.redpeppix.de/images/dot.png #{tmp_path} #{final_path}"
        system(command)
      
        if true
          puts "command 2 = #{command}"
          puts "########################################################"
        end
      
        # answer request with final image
        [200, {"Content-Type" => "image/jpg"}, IO.read(final_path)]
      else
        [404, {}, []]
      end
    end
  end
end