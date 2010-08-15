# -*- coding: utf-8 -*-
require 'rubygems'
require 'sinatra'
require 'RMagick'
require 'hpricot'
require 'open-uri'
require 'RMagick'
require 'hpricot'
require 'open-uri'
include Magick

get '/' do
  erb :index
end

get "/:user" do
  begin
    user_name = File.basename(params[:user])

    width = 8.9 / 2.54 * 72
    height = 9.8 / 2.54 * 72

    name_pt = 80
    twitter_pt = 26

    canvas = ImageList.new
    canvas.new_image(width, height)
    canvas.border!(2, 2, "black")

    draw = Draw.new do
      self.fill = 'black'
      self.stroke = 'transparent'
      self.font = File.expand_path('./fonts/ipagp.ttf')
    end

    # Name
    doc = Hpricot(open("http://twitter.com/#{user_name}"))
    user = doc.search(".entry-author").search(".fn").innerHTML.to_s

    # font size for ascii ... grrrrr ugly
    if user =~ /\w+/
      name_pt /= 2
    end

    draw.annotate(canvas, 0, 0, 10, 10, user.gsub(/\s/, "\n")) {
      self.pointsize = name_pt
      self.gravity = NorthWestGravity
    }

    # Twitter id
    draw.annotate(canvas, 0, 0, 10, 10, "@#{user_name}") {
      self.pointsize = twitter_pt
      self.gravity = SouthWestGravity
    }

    # Twitter Image
    icon = ImageList.new("http://img.tweetimag.es/i/#{user_name}_b")
    canvas.composite!(icon, SouthEastGravity, 10, 10, OverCompositeOp)
    canvas.write("/tmp/#{user_name}.jpg")

    # read
    File.open("/tmp/#{user_name}.jpg") do |f|
      content_type :jpg
      f.read
    end
  rescue
    raise Sinatra::NotFound
  end
end
