# -*- coding: utf-8 -*-
require 'rubygems'
require 'sinatra'
require 'RMagick'
require 'open-uri'
require 'json'
include Magick

get '/' do
  erb :index
end

def max_pt_per_px(width_px, string)
  str_length = string.split(//u).size
  pt = (width_px / str_length).to_i
  pt *= 2 if string =~ /\A[\(\)@\w\s]+\z/
  return pt
end

get "/:user" do
  begin
    user_name = File.basename(params[:user])

    unless File.exist?("/tmp/#{user_name}.jpg")
      width = 8.9 / 2.54 * 72
      height = 9.8 / 2.54 * 72

      canvas = ImageList.new
      canvas.new_image(width, height)
      canvas.border!(2, 2, "black")

      draw = Draw.new do
        self.fill = 'black'
        self.stroke = 'transparent'
        self.font = File.expand_path('./fonts/ipag.ttf')
      end

      # Name
      json = open("http://api.twitter.com/1/users/show/#{user_name}.json")
      user = JSON.parse(json.read)
      user_real_name = user["name"]

      start_margin = 3
      user_real_name.split(/\s/).each do |str|
        pt = max_pt_per_px(width - 20, str)
        draw.annotate(canvas, 0, 0, 10, start_margin, str) {
          self.pointsize = pt
          self.gravity = NorthWestGravity
        }
        start_margin += (pt - 5)
      end

      # Twitter id
      draw.annotate(canvas, 0, 0, 10, 5, "@#{user_name}") {
        self.pointsize = max_pt_per_px(width - 20 - 72, "@#{user_name}")
        self.gravity = SouthWestGravity
      }

      # Twitter Image
      icon = ImageList.new("http://img.tweetimag.es/i/#{user_name}_b")
      canvas.composite!(icon, SouthEastGravity, 10, 10, OverCompositeOp)
      canvas.write("/tmp/#{user_name}.jpg")
    end

    # read
    File.open("/tmp/#{user_name}.jpg") do |f|
      content_type :jpg
      f.read
    end
  rescue
    raise Sinatra::NotFound
  end
end
