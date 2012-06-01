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
        debug = request.params["debug"] == "true"

        coords = pix.coords.split(",")
        padding = 30
        x_coords = []
        y_coords = []
        if coords.count == 2
          x_coords << coords.first.to_i
          y_coords << coords.last.to_i
        else
          coords.each_index do |x|
            x.even? ? x_coords << coords[x].to_i : y_coords << coords[x].to_i
          end
        end

        left   = [(x_coords.sort.first-padding), 0].max
        top    = [(y_coords.sort.first-padding), 0].max
        width  = coords.count == 2 ? padding*2 : (x_coords.sort.last + padding - left)
        height = coords.count == 2 ? padding*2 : (y_coords.sort.last + padding - top)
        if debug
          Rails.logger.info("width: #{width}")
          Rails.logger.info("height: #{height}")
          Rails.logger.info("top: #{top}")
          Rails.logger.info("left: #{left}")
          Rails.logger.info(coords.to_yaml)
          Rails.logger.info("Y-coords:")
          Rails.logger.info(y_coords.sort.to_yaml)
          Rails.logger.info("X-coords:")
          Rails.logger.info(x_coords.sort.to_yaml)
          Rails.logger.info("")
          Rails.logger.info("(width-height)/2: #{(width-height)/2}") if width > height
          Rails.logger.info("(height-width)/2: #{(height-width)/2}") if height > width
          Rails.logger.info("top-^: #{top-(width-height)/2}") if width > height
          Rails.logger.info("left-^: #{left-(height-width)/2}") if height > width
          Rails.logger.info("curl -L -s -G #{pix.image.image_path} -o #{img_path}") unless File.exists?(img_path)
        end

        # load image and save it locally if it does not exist
        system("curl -L -s -G \"#{pix.image.image_path}\" -o #{img_path}") unless File.exists?(img_path)

        # crop image using ImageMagick

        if width == height
          # image is quadratic -> win
          command = "convert #{img_path} -crop #{width}x#{height}+#{left}+#{top}! #{tmp_path}"
        elsif width > height
          # image is wider than high, top crop marker must be lowered by half the sides difference
          command = "convert #{img_path} -crop #{width}x#{width}+#{left}+#{top-((width-height)/2)}! #{tmp_path}"
        else
          # image is higher than wide, left crop marker must be lowered by half the sides difference
          command = "convert #{img_path} -crop #{height}x#{height}+#{left-((height-width)/2)}+#{top}! #{tmp_path}"
        end

        Rails.logger.info command if debug
        system(command)

        # put PIX-dot in center of the cropped image
        command = "composite -gravity center #{Rails.root}/dot.png #{tmp_path} #{final_path}"
        Rails.logger.info command if debug
        system(command)

        # answer request with final image
        if File.exists?(final_path)
          [200, {"Content-Type" => "image/jpg"}, IO.read(final_path)]
        else
          [404, {}, []]
        end
      else
        [404, {}, []]
      end
    end
  end
end