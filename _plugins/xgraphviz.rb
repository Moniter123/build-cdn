# (The MIT License)
# 
# Copyright © 2013 Ibrahim Maguiraga
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the ‘Software’), to deal in
# the Software without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
# of the Software, and to permit persons to whom the Software is furnished to do
# so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED ‘AS IS’, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# ##Command to produce the output: "neato -Tsvg frameworks.gv  > neato-frameworks.svg  &&  dot -Tsvg frameworks.gv > dot-frameworks.svg  &&  circo -Tsvg frameworks.gv > circo-frameworks.svg &&  twopi -Tsvg frameworks.gv > twopi-frameworks.svg &&  fdp -Tsvg frameworks.gv > fdp-frameworks.svg && sfdp -Tsvg frameworks.gv > sfdp-frameworks.svg && patchwork -Tsvg frameworks.gv > patch-frameworks.svg"

# dot -Kneato -Tsvg -o framewoks.svg frameworks.gv 

require 'digest'
require 'liquid'
require 'open3'

#relative to current directory

module Jekyll
  module XTags
    class XGraphvizBlock < Liquid::Block
      include Liquid::StandardFilters
#xgraphix:
# destination  : "assets/graphviz"
#
      #safe true
      #priority :low

      GRAPHVIZ_DIR = "assets/graphviz"
      DIV_CLASS_ATTR = "container"
      # The regular expression syntax checker. Start with the language specifier.
      # Follow that by zero or more space separated options that take one of two
      # forms:
      #
      # 1. name
      # 2. name=value
      SYNTAX = /^([a-zA-Z0-9.+#-]+)((\s+\w+(=\w+)?)*)$/

      def initialize(tag_name, markup, tokens)
        super
        puts("\n-> initialize "+markup)

        @layout = "unknown"
        @inline = true
        @link = false
        @url = "#{Digest::MD5.hexdigest(Time.now.to_s)}.gv"
        @opts = ""
        @class = ""
        @style = ""
        @graphviz_dir = GRAPHVIZ_DIR
        

        @format, @params = markup.strip.split(' ', 2);
        @tag_name = tag_name
        case tag_name
          when 'xdot' then  
            @layout = "dot"
          when 'xneato' then  
            @layout = "neato"
          when 'xtwopi' then  
            @layout = "twopi"
          when 'xcirco' then  
            @layout = "circo"
          else 
            raise "unknown liquid tag name: #{tag_name}"
        end
        #initialize options       
        parse_options(@params,tag_name)
   
      end

      def read_config(name, site)
        cfg = site.config["xgraphviz"]
        return if cfg.nil?
        value = cfg[name]
      end


      def split_params(params)
        return params.split(" ").map(&:strip)
      end

      def parse_options(params,tag_name)
          if not(defined?(@format)) or @format.nil?
            @format = "svg"
          end

          if defined?(params) && not( params.nil?)
            if defined?(params) && params != ''
              puts("===> params -> "+params.to_s)
              options = split_params(params)

                options.each do |opt|
                    key, value = opt.split('=')
                      unless value.nil? or value.empty? then
                        value = value.gsub(/[\\'\\"]/,"")
                      end

                    puts("===> option [#{key} = #{value}]")
                    case key
                      when 'svg' then  
                        @format = key

                      when 'class' then  
                        @class = value

                      when 'style' then  
                        @style = value

                      when 'png' then  
                        @format = key
                        @inline = false

                      when 'format' then  
                        unless value.nil? or value.empty? then 
                          @format = value
                        end
                        
                      when 'opts' then  
                        unless value.nil? or value.empty? then
                          @opts = value
                        end

                      when 'url' then  
                        unless value.nil? or value.empty? then
                          @url = value
                          @link = true
                        end
                        
                      when 'inline' then  
                        @inline=true
                        unless value.nil? or value.empty? then
                          @inline = value == 'true'
                        end

                      else 
                        puts "unsupported option: #{key}"
                    end
                    
                end
                
              #end
            else
              raise SyntaxError.new <<-eos
            Syntax Error in tag #{tag_name} while parsing the following markup:

              #{params}

            Valid syntax: <xdot|xneato|xcirco|xtwopi> <png|svg> [param='value' param2='value'] 
            param='value': i.e(keep=<true|false> inline=<true|false> url=<filename> h=<height> w=<width> opts=<options>)

            eos
            end
          end

          if @format == 'png' then 
            @inline = false
          end
      end


      def render(context) 
      #initialize options 
        site = context.registers[:site]
        value = read_config("destination", site)
      
        @graphviz_dir = value if !value.nil?
      
       puts("\n=> render")      
        folder = File.join(site.source, @graphviz_dir) #dest
        FileUtils.mkdir_p(folder)
            
        puts("\tfolder -> "+folder.to_s)
          puts("\tinline -> #{@inline}")
          puts("\tlink -> #{@link}")
          puts("\turl -> #{@url}")
          puts("\tlayout -> #{@layout}")
          puts("\tformat -> #{@format}")
       
        non_markdown = /(&amp|&lt|&nbsp|&quot|&gt|<\/p>|<\/h.>)/m
        
        # preprocess text
        code = super
  
        # Used for debug..
        # fd = IO.sysopen "/dev/tty", "w"
        # ios = IO.new(fd,"w")
        # ios.puts code
   
        svg = ""
        inputfile = nil

        if @link == true then
          inputfile = File.join(site.source,@url)   
        else
          @url = "#{Digest::MD5.hexdigest(code)}.gv"  
        end 
        svg = generate_graph_from_content(context, code,folder,inputfile)   
        output = wrap_with_div(svg)
        
        output
        #output trigger last stdout is what gets display
      end

      def blank?
        false
      end

      def generate_graph_from_content(context, code, folder, inputfile)
        dot_cmd = ""     
        site = context.registers[:site]

        if @inline == true then
          dot_cmd = "dot -K#{@layout} -T#{@format} #{@opts} #{inputfile}"

          svg = run_dot_cmd(dot_cmd,code)
          svg = remove_declarations(svg)
          svg = remove_title(svg)
          svg = remove_font(svg)
          return svg

        else
          filename = "gen-"+File.basename(@url)+"."+@format
          destination = File.join(folder,filename).strip
          dot_cmd = "dot -K#{@layout} -T#{@format} -o #{destination} #{@opts} #{inputfile}"
          output = File.join(@graphviz_dir,filename)

          run_dot_cmd(dot_cmd,code)
          puts("\n output ="+output)
          # Add the file to the list of static files for the final copy once generated
          st_file = Jekyll::StaticFile.new(site, site.source, @graphviz_dir, filename)#@graphviz_dir, filename)
          site.static_files << st_file

          if @style.empty? or @style.nil?
            @style = ""
          else
            @style = %[style="#{@style}"]
          end

          return "<img #{@style} src='#{output}'>"
        end
      end

      def run_dot_cmd(dot_cmd,code)
        puts("\tdot_cmd -> "+dot_cmd)
        #IO.popen(dot_cmd, 'w') do |pipe|
        #  pipe.puts(code)
        #  pipe.close_write
        #end
        #Process.spawn(dot_cmd)
        #
        Open3.popen3( dot_cmd ) do |stdin, stdout, stderr, wait_thr|
          stdout.binmode
          stdin.print(code)
          stdin.close

          err = stderr.read
          if not (err.nil? || err.strip.empty?)
            raise "Error from #{dot_cmd}:\n#{err}"
          end

          svg = stdout.read

          svg.force_encoding('UTF-8')
          exit_status = wait_thr.value
            unless exit_status.success?
              abort "FAILED !!! #{dot_cmd}"
            end
          return svg
        end
      end


      def remove_declarations(svg)
        svg.sub(/<!DOCTYPE .+?>/im,'').sub(/<\?xml .+?\?>/im,'')
      end

      def remove_xmlns_attrs(svg)
        svg.sub(%[xmlns="http://www.w3.org/2000/svg"], '')
          .sub(%[xmlns:xlink="http://www.w3.org/1999/xlink"], '')
      end

      def remove_title(svg)
        svg.gsub(/<title.*?>.*?<\/title>/im,'')
      end

      def remove_font(svg)
        svg.gsub(/ font-family=".*?"/im,'').gsub(/ font-size=".*?"/im, '')
      end

      def remove_fill(svg)
        svg.gsub(/ fill=".*?"/im, '')
      end

      def remove_stroke(svg)
        svg.gsub(/ stroke=".*?"/im, '')
      end

      def wrap_with_div(svg)
        if @class.empty? or @class.nil?
          @class = ""
        else
          @class = %[class="#{@class}"]
        end

        if @style.empty? or @style.nil?
          @style = ""
        else
          @style = %[style="#{@style}"]
        end

        %[<figure class="graphviz">#{svg}</figure>]
      end

    end

  end
end

Liquid::Template.register_tag('xdot', Jekyll::XTags::XGraphvizBlock)
Liquid::Template.register_tag('xneato', Jekyll::XTags::XGraphvizBlock)
Liquid::Template.register_tag('xtwopi', Jekyll::XTags::XGraphvizBlock)
Liquid::Template.register_tag('xcirco', Jekyll::XTags::XGraphvizBlock)
