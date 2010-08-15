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
  length = string.split(/\s/).map{|i| i.split(//u).size }.max
  pt = (width_px / length).to_i
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
      draw.annotate(canvas, 0, 0, 10, 3, user_real_name.gsub(/\s/, "\n")) {
        self.pointsize = max_pt_per_px(width - 20, user_real_name)
        self.gravity = NorthWestGravity
      }

      # Twitter id
      draw.annotate(canvas, 0, 0, 10, 10, "@#{user_name}") {
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
