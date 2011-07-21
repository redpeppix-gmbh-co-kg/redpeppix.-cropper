# Allow the metal piece to run in isolation
require File.expand_path('../../../config/environment',  __FILE__) unless defined?(Rails)

class Cropper
  class << self
    def call(env)
      if env["PATH_INFO"] =~ /^\/crop/
        request = Rack::Request.new(env)
        pix = Pix.find(request.params["id"].to_i) || raise(ActiveRecord::RecordNotFound)

        img_path = "#{Rails.root}/tmp/crops/images/img_#{pix.image.id}#{File.extname(pix.image.image_path)}"
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
        
        # load image and save it locally if it does not exist
        system("curl -s -G #{pix.image.image_path} -o #{img_path}") unless File.exists?(img_path)

        # crop image using ImageMagick

        if width == height
          
          # image is quadratic -> win
          command = "convert #{img_path} -crop #{width}x#{height}+#{left}+#{top}! #{tmp_path}"
        elsif width > height
          
          # image is wider than high, top crop marker must be lowered by half the sides difference
          command = "convert #{img_path} -crop #{width}x#{width}+#{left}+#{top-((height-width)/2)}! #{tmp_path}"
        else
          
          # image is higher than wide, left crop marker must be lowered by half the sides difference
          command = "convert #{img_path} -crop #{height}x#{height}+#{left-((height-width)/2)}+#{top}! #{tmp_path}"
        end
        
        system(command)

        # put PIX-dot in center of the cropped image
        command = "composite -gravity center #{Rails.root}/dot.png #{tmp_path} #{final_path}"
        Rails.logger.info command
        system(command)

        # answer request with final image
        [200, {"Content-Type" => "image/jpg"}, IO.read(final_path)]
      else
        [404, {}, []]
      end
    end
  end
end