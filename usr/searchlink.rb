#!/usr/bin/env ruby
# encoding: utf-8

SILENT = ENV['SL_SILENT'] =~ /false/i ? false : true


# SearchLink by Brett Terpstra 2015 <http://brettterpstra.com/projects/searchlink/>
# MIT License, please maintain attribution
require 'net/https'
require 'uri'
require 'rexml/document'
require 'shellwords'
require 'yaml'
require 'cgi'
require 'fileutils'
require 'tempfile'
require 'zlib'
require 'time'
require 'json'
require 'erb'

# import
require 'tokens' if File.exist?('lib/tokens.rb')

module SL
  module Util
    class << self
      ## Execute system command with deadman's switch
      ##
      ## <https://stackoverflow.com/questions/8292031/ruby-timeouts-and-system-commands>
      ## <https://stackoverflow.com/questions/12189904/fork-child-process-with-timeout-and-capture-output>
      ##
      ## @param      cmd      The command to execute
      ## @param      timeout  The timeout
      ##
      ## @return     [String] STDOUT output
      ##
      def exec_with_timeout(cmd, timeout)
        begin
          # stdout, stderr pipes
          rout, wout = IO.pipe
          rerr, werr = IO.pipe
          stdout, stderr = nil

          pid = Process.spawn(cmd, pgroup: true, out: wout, err: werr)

          Timeout.timeout(timeout) do
            Process.waitpid(pid)

            # close write ends so we can read from them
            wout.close
            werr.close

            stdout = rout.readlines.join
            stderr = rerr.readlines.join
          end
        rescue Timeout::Error
          Process.kill(-9, pid)
          Process.detach(pid)
        ensure
          wout.close unless wout.closed?
          werr.close unless werr.closed?
          # dispose the read ends of the pipes
          rout.close
          rerr.close
        end

        stdout&.strip
      end

      ##
      ## Execute a search with deadman's switch
      ##
      ## @param      search   [Proc] The search command
      ## @param      timeout  [Number] The timeout
      ##
      ## @return     [Array] url, title, link_text
      ##
      def search_with_timeout(search, timeout)
        url = nil
        title = nil
        link_text = nil

        begin
          Timeout.timeout(timeout) do
            url, title, link_text = search.call
          end
        rescue Timeout::Error
          SL.add_error('Timeout', 'Search timed out')
          url, title, link_text = false
        end

        [url, title, link_text]
      end

      ##
      ## Get the path for a cache file
      ##
      ## @param      filename  [String]  The filename to
      ##                       generate the cache for
      ##
      ## @return     [String] path to new cache file
      ##
      def cache_file_for(filename)
        cache_folder = File.expand_path('~/.local/share/searchlink/cache')
        FileUtils.mkdir_p(cache_folder) unless File.directory?(cache_folder)
        File.join(cache_folder, filename.sub(/(\.cache)?$/, '.cache'))
      end
    end
  end
end

module SL
  # Semantic versioning library
  class SemVer
    attr_accessor :maj, :min, :patch, :pre

    # Initialize a Semantic Version object
    #
    # @param      version_string  [String] a semantic version number
    #
    # @return     [SemVer] SemVer object
    #
    def initialize(version_string)
      raise "Invalid semantic version number: #{version_string}" unless version_string.valid_version?

      @maj, @min, @patch = version_string.split(/\./)
      @pre = nil
      if @patch =~ /(-?[^0-9]+\d*)$/
        @pre = Regexp.last_match(1).sub(/^-/, '')
        @patch = @patch.sub(/(-?[^0-9]+\d*)$/, '')
      end

      @maj = @maj.to_i
      @min = @min.to_i
      @patch = @patch.to_i
    end

    ##
    ## SemVer String helpers
    ##
    class ::String
      # Test if given string is a valid semantic version
      # number with major, minor and patch (and optionally
      # pre)
      #
      # @return     [Boolean] string is semantic version number
      #
      def valid_version?
        pattern = /^\d+\.\d+\.\d+(-?([^0-9]+\d*))?$/
        self =~ pattern ? true : false
      end
    end

    ##
    ## Test if self is older than a semantic version number
    ##
    ## @param      semver  [String,SemVer] The semantic version number or SemVer object
    ##
    ## @return     [Boolean] true if semver is older
    ##
    def older_than(other)
      latest = other.is_a?(SemVer) ? other : SemVer.new(other)

      return false if latest.equal?(self)

      if @maj > latest.maj
        false
      elsif @maj < latest.maj
        true
      elsif @min > latest.min
        false
      elsif @min < latest.min
        true
      elsif @patch > latest.patch
        false
      elsif @patch < latest.patch
        true
      else
        return false if @pre.nil? && latest.pre.nil?

        return true if @pre.nil? && !latest.pre.nil?

        return false if !@pre.nil? && latest.pre.nil?

        @pre < latest.pre
      end
    end

    ##
    ## @see        #older_than
    ##
    def <(other)
      older_than(other)
    end

    ##
    ## Test if self is newer than a semantic version number
    ##
    ## @param      semver  [String,SemVer] The semantic version number or SemVer object
    ##
    ## @return     [Boolean] true if semver is newer
    ##
    def newer_than(other)
      v = other.is_a?(SemVer) ? other : SemVer.new(other)
      v.older_than(self) && !v.equal?(self)
    end

    ##
    ## @see        #newer_than
    ##
    def >(other)
      newer_than(other)
    end

    ##
    ## Test if self is equal to other
    ##
    ## @param      other [String,SemVer] The other semantic version number
    ##
    ## @return     [Boolean] values are equal
    ##
    def equal?(other)
      v = other.is_a?(SemVer) ? other : SemVer.new(other)

      v.maj == @maj && v.min == @min && v.patch == @patch && v.pre == @pre
    end

    ##
    ## @see #equal?
    ##
    def ==(other)
      equal?(other)
    end

    def inspect
      {
        object_id: object_id,
        maj: @maj,
        min: @min,
        patch: @patch,
        pre: @pre
      }
    end

    def to_s
      ver = [@maj, @min, @patch].join('.')
      @pre.nil? ? ver : "#{ver}-#{@pre}"
    end
  end
end

module SL
  VERSION = '2.3.50'
end

module SL
  class << self
    def version_check
      cachefile = File.expand_path('~/.searchlink_update_check')
      if File.exist?(cachefile)
        last_check, latest_tag = IO.read(cachefile).strip.split(/\|/)
        last_time = Time.parse(last_check)
      else
        latest_tag = new_version?
        last_time = Time.now
      end

      if last_time + (24 * 60 * 60) < Time.now
        latest_tag = new_version?
        last_time = Time.now
      end

      latest_tag ||= SL::VERSION
      latest = SemVer.new(latest_tag)
      current = SemVer.new(SL::VERSION)
      
      File.open(cachefile, 'w') { |f| f.puts("#{last_time.strftime('%c')}|#{latest.to_s}") }

      return "SearchLink v#{current.to_s}, #{latest.to_s} available. Run 'update' to download." if latest_tag && current.older_than(latest)

      "SearchLink v#{current.to_s}"
    end

    # Check for a newer version than local copy using GitHub release tag
    #
    # @return false if no new version, or semantic version of latest release
    def new_version?
      cmd = [
        'curl -SsL -H "Accept: application/vnd.github+json"',
        '-H "X-GitHub-Api-Version: 2022-11-28"'
      ]
      cmd.push(%(-H "Authorization: Bearer #{Secrets::GH_AUTH_TOKEN}")) if defined? Secrets::GH_AUTH_TOKEN

      cmd.push('https://api.github.com/repos/ttscoff/searchlink/releases/latest')
      res = `#{cmd.join(' ')}`.strip

      res = res.force_encoding('utf-8') if RUBY_VERSION.to_f > 1.9
      result = JSON.parse(res)

      if result
        latest_tag = result['tag_name']

        return false unless latest_tag

        return false if latest_tag =~ /^#{Regexp.escape(SL::VERSION)}$/

        latest = SemVer.new(latest_tag)
        current = SemVer.new(SL::VERSION)

        return latest_tag if current.older_than(latest)
      else
        warn 'Check for new version failed.'
      end

      false
    end

    def update_searchlink
      new_version = SL.new_version?
      if new_version
        folder = File.expand_path('~/Downloads')
        services = File.expand_path('~/Library/Services')
        dl = File.join(folder, 'SearchLink.zip')
        `curl -SsL -o "#{dl}" https://github.com/ttscoff/searchlink/releases/latest/download/SearchLink.zip`
        Dir.chdir(folder)
        `unzip -qo #{dl} -d #{folder}`
        FileUtils.rm(dl)

        ['SearchLink', 'SearchLink File', 'Jump to SearchLink Error'].each do |workflow|
          wflow = "#{workflow}.workflow"
          src = File.join(folder, 'SearchLink Services', wflow)
          dest = File.join(services, wflow)
          if File.exist?(src) && File.exist?(dest)
            FileUtils.rm_rf(dest)
            FileUtils.mv(src, dest, force: true)
          end
        end
        add_output("Installed SearchLink #{new_version}")
        FileUtils.rm_rf('SearchLink Services')
      else
        add_output('Already up to date.')
      end
    end
  end
end

# Array helpers
class ::Array
  # Finds the longest element in a given array.
  def longest_element
    group_by(&:size).max.last[0]
  end
end

# String helpers
class ::String
  # URL Encode string
  #
  # @return     [String] url encoded string
  #
  def url_encode
    ERB::Util.url_encode(gsub(/%22/, '"'))
  end

  ##
  ## Adds ?: to any parentheticals in a regular expression
  ## to avoid match groups
  ##
  ## @return     [String] modified regular expression
  ##
  def normalize_trigger
    gsub(/\((?!\?:)/, '(?:').downcase
  end

  ##
  ## Generate a spacer based on character widths for help dialog display
  ##
  ## @return     [String] string containing tabs
  ##
  def spacer
    len = length
    scan(/[mwv]/).each { len += 1 }
    scan(/t/).each { len -= 1 }
    case len
    when 0..3
      "\t\t"
    when 4..12
      " \t"
    end
  end

  # parse command line flags into long options
  def parse_flags
    gsub(/(\+\+|--)([dirtvs]+)\b/) do
      m = Regexp.last_match
      bool = m[1] == '++' ? '' : 'no-'
      output = ' '
      m[2].split('').each do |arg|
        output += case arg
                  when 'd'
                    "--#{bool}debug "
                  when 'i'
                    "--#{bool}inline "
                  when 'r'
                    "--#{bool}prefix_random "
                  when 't'
                    "--#{bool}include_titles "
                  when 'v'
                    "--#{bool}validate_links "
                  when 's'
                    "--#{bool}remove_seo"
                  else
                    ''
                  end
      end

      output
    end.gsub(/ +/, ' ')
  end

  def parse_flags!
    replace parse_flags
  end

  ##
  ## Convert file-myfile-rb to myfile.rb
  ##
  ## @return     { description_of_the_return_value }
  ##
  def fix_gist_file
    sub(/^file-/, '').sub(/-([^\-]+)$/, '.\1')
  end

  # Turn a string into a slug, removing spaces and
  # non-alphanumeric characters
  #
  # @return     [String] slugified string
  #
  def slugify
    downcase.gsub(/[^a-z0-9_]/i, '-').gsub(/-+/, '-').sub(/-?$/, '')
  end

  # Destructive slugify
  # @see #slugify
  def slugify!
    replace slugify
  end

  ##
  ## Remove newlines, escape quotes, and remove Google
  ## Analytics strings
  ##
  ## @return     [String] cleaned URL/String
  ##
  def clean
    gsub(/\n+/, ' ')
      .gsub(/"/, '&quot')
      .gsub(/\|/, '-')
      .gsub(/([&?]utm_[scm].+=[^&\s!,.)\]]++?)+(&.*)/, '\2')
      .sub(/\?&/, '').strip
  end

  # convert itunes to apple music link
  #
  # @return [String] apple music link
  def to_am
    input = dup
    input.sub!(%r{/itunes\.apple\.com}, 'geo.itunes.apple.com')
    append = input =~ %r{\?[^/]+=} ? '&app=music' : '?app=music'
    input + append
  end

  ##
  ## Remove the protocol from a URL
  ##
  ## @return     [String] just hostname and path of URL
  ##
  def remove_protocol
    sub(%r{^(https?|s?ftp|file)://}, '')
  end

  ##
  ## Return just the path of a URL
  ##
  ## @return     [String] The path.
  ##
  def url_path
    URI.parse(self).path
  end

  # Extract the most relevant portions from a URL path
  #
  # @return     [Array] array of relevant path elements
  #
  def path_elements
    path = url_path
    # force trailing slash
    path.sub!(%r{/?$}, '/')
    # remove last path element
    path.sub!(%r{/[^/]+[.\-][^/]+/$}, '')
    # remove starting/ending slashes
    path.gsub!(%r{(^/|/$)}, '')
    # split at slashes, delete sections that are shorter
    # than 5 characters or only consist of numbers
    path.split(%r{/}).delete_if { |section| section =~ /^\d+$/ || section.length < 5 }
  end

  ##
  ## Destructive punctuation close
  ##
  ## @see        #close_punctuation
  ##
  def close_punctuation!
    replace close_punctuation
  end

  ##
  ## Complete incomplete punctuation pairs
  ##
  ## @return     [String] string with all punctuation
  ##             properly paired
  ##
  def close_punctuation
    return self unless self =~ /[“‘\[(<]/

    words = split(/\s+/)

    punct_chars = {
      '“' => '”',
      '‘' => '’',
      '[' => ']',
      '(' => ')',
      '<' => '>'
    }

    left_punct = []

    words.each do |w|
      punct_chars.each do |k, v|
        left_punct.push(k) if w =~ /#{Regexp.escape(k)}/
        left_punct.delete_at(left_punct.rindex(k)) if w =~ /#{Regexp.escape(v)}/
      end
    end

    tail = ''
    left_punct.reverse.each { |c| tail += punct_chars[c] }

    gsub(/[^a-z)\]’”.…]+$/i, '...').strip + tail
  end

  ##
  ## Destructively remove SEO elements from a title
  ##
  ## @param      url   The url of the page from which the
  ##                   title came
  ##
  ## @see        #remove_seo
  ##
  def remove_seo!(url)
    replace remove_seo(url)
  end

  ##
  ## Remove SEO elements from a title
  ##
  ## @param      url   The url of the page from which the title came
  ##
  ## @return     [String] cleaned title
  ##
  def remove_seo(url)
    title = dup
    url = URI.parse(url)
    host = url.hostname
    unless host
      return self unless SL.config['debug']

      SL.add_error('Invalid URL', "Could not remove SEO for #{url}")
      return self

    end

    path = url.path
    root_page = path =~ %r{^/?$} ? true : false

    title.gsub!(/\s*(&ndash;|&mdash;)\s*/, ' - ')
    title.gsub!(/&[lr]dquo;/, '"')
    title.gsub!(/&[lr]dquo;/, "'")
    title.gsub!(/&#8211;/, ' — ')
    title = CGI.unescapeHTML(title)
    title.gsub!(/ +/, ' ')

    seo_title_separators = %w[| » « — – - · :]

    begin
      re_parts = []

      host_parts = host.sub(/(?:www\.)?(.*?)\.[^.]+$/, '\1').split(/\./).delete_if { |p| p.length < 3 }
      h_re = !host_parts.empty? ? host_parts.map { |seg| seg.downcase.split(//).join('.?') }.join('|') : ''
      re_parts.push(h_re) unless h_re.empty?

      # p_re = path.path_elements.map{|seg| seg.downcase.split(//).join('.?') }.join('|')
      # re_parts.push(p_re) if p_re.length > 0

      site_re = "(#{re_parts.join('|')})"

      dead_switch = 0

      while title.downcase.gsub(/[^a-z]/i, '') =~ /#{site_re}/i

        break if dead_switch > 5

        seo_title_separators.each_with_index do |sep, i|
          parts = title.split(/ *#{Regexp.escape(sep)} +/)

          next if parts.length == 1

          remaining_separators = seo_title_separators[i..].map { |s| Regexp.escape(s) }.join('')
          seps = Regexp.new("^[^#{remaining_separators}]+$")

          longest = parts.longest_element.strip

          unless parts.empty?
            parts.delete_if do |pt|
              compressed = pt.strip.downcase.gsub(/[^a-z]/i, '')
              compressed =~ /#{site_re}/ && pt =~ seps ? !root_page : false
            end
          end

          title = if parts.empty?
                    longest
                  elsif parts.length < 2
                    parts.join(sep)
                  elsif parts.length > 2
                    parts.longest_element.strip
                  else
                    parts.join(sep)
                  end
        end
        dead_switch += 1
      end
    rescue StandardError => e
      return self unless SL.config['debug']

      SL.add_error("Error SEO processing title for #{url}", e)
      return self
    end

    seps = Regexp.new(" *[#{seo_title_separators.map { |s| Regexp.escape(s) }.join('')}] +")
    if title =~ seps
      seo_parts = title.split(seps)
      title = seo_parts.longest_element.strip if seo_parts.length.positive?
    end

    title && title.length > 5 ? title.gsub(/\s+/, ' ') : CGI.unescapeHTML(self)
  end

  ##
  ## Truncate in place
  ##
  ## @see        #truncate
  ##
  ## @param      max   [Number]  The maximum length
  ##
  def truncate!(max)
    replace truncate(max)
  end

  ##
  ## Truncate string to given length, preserving words
  ##
  ## @param      max   [Number]  The maximum length
  ##
  def truncate(max)
    return self if length < max

    trunc_title = []

    words = split(/\s+/)
    words.each do |word|
      break unless trunc_title.join(' ').length.close_punctuation + word.length <= max

      trunc_title << word
    end

    trunc_title.empty? ? words[0] : trunc_title.join(' ')
  end

  ##
  ## Test an AppleScript response, substituting nil for
  ## 'Missing Value'
  ##
  ## @return     [Nil, String] nil if string is
  ##             "missing value"
  ##
  def nil_if_missing
    return nil if self =~ /missing value/

    self
  end

  ##
  ## Score string based on number of matches, 0 - 10
  ##
  ## @param      terms       [String]      The terms to
  ##                         match
  ## @param      separator   [String]  The word separator
  ## @param      start_word  [Boolean] Require match to be
  ##                         at beginning of word
  ##
  def matches_score(terms, separator: ' ', start_word: true)
    matched = 0
    regexes = terms.to_rx_array(separator: separator, start_word: start_word)

    regexes.each do |rx|
      matched += 1 if self =~ rx
    end

    return 0 if matched.zero?

    (matched / regexes.count.to_f) * 10
  end

  ##
  ## Test if self contains exactl match for string (case insensitive)
  ##
  ## @param      string [String] The string to match
  ##
  def matches_exact(string)
    comp = gsub(/[^a-z0-9 ]/i, '')
    comp =~ /\b#{string.gsub(/[^a-z0-9 ]/i, '').split(/ +/).map { |s| Regexp.escape(s) }.join(' +')}/i
  end

  ##
  ## Test that self does not contain any of terms
  ##
  ## @param      terms [String] The terms to test
  ##
  def matches_none(terms)
    rx_terms = terms.is_a?(String) ? terms.to_rx_array : terms
    rx_terms.each { |rx| return false if gsub(/[^a-z0-9 ]/i, '') =~ rx }
    true
  end

  ##
  ## Test if self contains any of terms
  ##
  ## @param      terms [String] The terms to test
  ##
  def matches_any(terms)
    rx_terms = terms.is_a?(String) ? terms.to_rx_array : terms
    rx_terms.each { |rx| return true if gsub(/[^a-z0-9 ]/i, '') =~ rx }
    false
  end

  ##
  ## Test that self matches every word in terms
  ##
  ## @param      terms [String] The terms to test
  ##
  def matches_all(terms)
    rx_terms = terms.is_a?(String) ? terms.to_rx_array : terms
    rx_terms.each { |rx| return false unless gsub(/[^a-z0-9 ]/i, '') =~ rx }
    true
  end

  ##
  ## Break a string into an array of Regexps
  ##
  ## @param      separator   [String]  The word separator
  ## @param      start_word  [Boolean] Require matches at
  ##                         start of word
  ##
  ## @return     [Array] array of regular expressions
  ##
  def to_rx_array(separator: ' ', start_word: true)
    bound = start_word ? '\b' : ''
    split(/#{separator}/).map { |arg| /#{bound}#{Regexp.escape(arg.gsub(/[^a-z0-9]/i, ''))}/i }
  end
end

# = plist
#
# Copyright 2006-2010 Ben Bleything and Patrick May
# Distributed under the MIT License
module Plist ; end

# === Load a plist file
# This is the main point of the library:
#
#   r = Plist::parse_xml( filename_or_xml )
module Plist
  def Plist::parse_xml( filename_or_xml )
    listener = Listener.new
    parser = StreamParser.new(filename_or_xml, listener)
    parser.parse
    listener.result
  end

  class Listener
    attr_accessor :result, :open

    def initialize
      @result = nil
      @open = Array.new
    end

    def tag_start(name, attributes)
      @open.push PTag::mappings[name].new
    end

    def text( contents )
      @open.last.text = contents if @open.last
    end

    def tag_end(name)
      last = @open.pop
      if @open.empty?
        @result = last.to_ruby
      else
        @open.last.children.push last
      end
    end
  end

  class StreamParser
    def initialize( plist_data_or_file, listener )
      if plist_data_or_file.respond_to? :read
        @xml = plist_data_or_file.read
      elsif File.exists? plist_data_or_file
        @xml = File.read( plist_data_or_file )
      else
        @xml = plist_data_or_file
      end

      @listener = listener
    end

    TEXT       = /([^<]+)/
    XMLDECL_PATTERN = /<\?xml\s+(.*?)\?>*/um
    DOCTYPE_PATTERN = /\s*<!DOCTYPE\s+(.*?)(\[|>)/um
    COMMENT_START = /\A<!--/u
    COMMENT_END = /.*?-->/um

    def parse
      plist_tags = PTag::mappings.keys.join('|')
      start_tag  = /<(#{plist_tags})([^>]*)>/i
      end_tag    = /<\/(#{plist_tags})[^>]*>/i

      require 'strscan'

      @scanner = StringScanner.new(@xml)
      until @scanner.eos?
        if @scanner.scan(COMMENT_START)
          @scanner.scan(COMMENT_END)
        elsif @scanner.scan(XMLDECL_PATTERN)
        elsif @scanner.scan(DOCTYPE_PATTERN)
        elsif @scanner.scan(start_tag)
          @listener.tag_start(@scanner[1], nil)
          if (@scanner[2] =~ /\/$/)
            @listener.tag_end(@scanner[1])
          end
        elsif @scanner.scan(TEXT)
          @listener.text(@scanner[1])
        elsif @scanner.scan(end_tag)
          @listener.tag_end(@scanner[1])
        else
          raise "Unimplemented element"
        end
      end
    end
  end

  class PTag
    @@mappings = { }
    def PTag::mappings
      @@mappings
    end

    def PTag::inherited( sub_class )
      key = sub_class.to_s.downcase
      key.gsub!(/^plist::/, '' )
      key.gsub!(/^p/, '')  unless key == "plist"

      @@mappings[key] = sub_class
    end

    attr_accessor :text, :children
    def initialize
      @children = Array.new
    end

    def to_ruby
      raise "Unimplemented: " + self.class.to_s + "#to_ruby on #{self.inspect}"
    end
  end

  class PList < PTag
    def to_ruby
      children.first.to_ruby if children.first
    end
  end

  class PDict < PTag
    def to_ruby
      dict = Hash.new
      key = nil

      children.each do |c|
        if key.nil?
          key = c.to_ruby
        else
          dict[key] = c.to_ruby
          key = nil
        end
      end

      dict
    end
  end

  class PKey < PTag
    def to_ruby
      CGI::unescapeHTML(text || '')
    end
  end

  class PString < PTag
    def to_ruby
      CGI::unescapeHTML(text || '')
    end
  end

  class PArray < PTag
    def to_ruby
      children.collect do |c|
        c.to_ruby
      end
    end
  end

  class PInteger < PTag
    def to_ruby
      text.to_i
    end
  end

  class PTrue < PTag
    def to_ruby
      true
    end
  end

  class PFalse < PTag
    def to_ruby
      false
    end
  end

  class PReal < PTag
    def to_ruby
      text.to_f
    end
  end

  require 'date'
  class PDate < PTag
    def to_ruby
      DateTime.parse(text)
    end
  end

  require 'base64'
  class PData < PTag
    def to_ruby
      data = Base64.decode64(text.gsub(/\s+/, ''))

      begin
        return Marshal.load(data)
      rescue Exception
        io = StringIO.new
        io.write data
        io.rewind
        return io
      end
    end
  end
end


# module Plist
#   VERSION = '3.1.0'
# end


module SL
  class << self
    attr_writer :config, :prev_config

    def config
      @config ||= SL::SearchLink.new({ echo: true })
    end

    def prev_config
      @prev_config ||= {}
    end
  end
end

module SL
  # Main SearchLink class
  class SearchLink
    # Values found in ~/.searchlink will override defaults in
    # this script

    def initialize(opt = {})
      SL.printout = opt[:echo] || false
      unless File.exist? File.expand_path('~/.searchlink')
        default_config = <<~ENDCONFIG
          # set to true to have an HTML comment included detailing any errors
          # Can be disabled per search with `--d`, or enabled with `++d`.
          debug: true
          # set to true to have an HTML comment included reporting results
          report: true

          # use Notification Center to display progress
          notifications: false

          # when running on a file, back up original to *.bak
          backup: true

          # Time limit for searches. Increase if your searches are regularly
          # timing out
          timeout: 15

          # change this to set a specific country for search (default US)
          country_code: US

          # set to true to force inline Markdown links. Can be disabled
          # per search with `--i`, or enabled with `++i`
          inline: false

          # set to true to include a random string in reference titles.
          # Avoids conflicts if you're only running on part of a document
          # or using SearchLink multiple times within a document
          prefix_random: true

          # set to true to add titles to links based on the page title
          # of the search result. Can be disabled per search with `--t`,
          # or enabled with `++t`.
          include_titles: false

          # set to true to attempt to remove SEO elements from page titles,
          # such that "Regular expressions for beginners | Brett Terpstra.com"
          # becomes "Regular expressions for beginners"
          remove_seo: false

          # confirm existence (200) of generated links. Can be disabled
          # per search with `--v`, or enabled with `++v`.
          validate_links: false

          # If the link text is left empty, always insert the page title
          # E.g. [](!g Search Text)
          empty_uses_page_title: false

          # Formatting for social links, use %service%, %user%, and %url%
          # E.g. "%user% on %service%" => "ttscoff on Twitter"
          #      "%service%/%user%" => "Twitter/ttscoff"
          #      "%url%" => "twitter.com/ttscoff"
          social_template: "%service%/%user%"

          # append affiliate link info to iTunes urls, empty quotes for none
          # example:
          # itunes_affiliate: "&at=10l4tL&ct=searchlink"
          itunes_affiliate: "&at=10l4tL&ct=searchlink"

          # to create Amazon affiliate links, set amazon_partner to your amazon
          # affiliate tag
          #    amazon_partner: "bretttercom-20"
          amazon_partner: "bretttercom-20"

          # To create custom abbreviations for Google Site Searches,
          # add to (or replace) the hash below.
          # "abbreviation" => "site.url",
          # This allows you, for example to use [search term](!bt)
          # as a shortcut to search brettterpstra.com (using a site-specific
          # Google search). Keys in this list can override existing
          # search trigger abbreviations.
          #
          # If a custom search starts with "http" or "/", it becomes
          # a simple replacement. Any instance of "$term" is replaced
          # with a URL-escaped version of your search terms.
          # Use $term1, $term2, etc. to replace in sequence from
          # multiple search terms. No instances of "$term" functions
          # as a simple shortcut. "$term" followed by a "d" lowercases
          # the replacement. Use "$term1d," "$term2d" to downcase
          # sequential replacements (affected individually).
          # Long flags (e.g. --no-validate_links) can be used after
          # any url in the custom searches.
          #
          # Use $terms to slugify all search terms, turning
          # "Markdown Service Tools" into "markdown-service-tools"
          custom_site_searches:
            bt: brettterpstra.com
            btt: https://brettterpstra.com/topic/$term1d
            bts: /search/$term --no-validate_links
            md: www.macdrifter.com
            ms: macstories.net
            dd: www.leancrew.com
            spark: macsparky.com
            man: http://man.cx/$term
            dev: developer.apple.com
            nq: http://nerdquery.com/?media_only=0&query=$term&search=1&category=-1&catid=&type=and&results=50&db=0&prefix=0
            gs: http://scholar.google.com/scholar?btnI&hl=en&q=$term&btnG=&as_sdt=80006
          # Remove or comment (with #) history searches you don't want
          # performed by `!h`. You can force-enable them per search, e.g.
          # `!hsh` (Safari History only), `!hcb` (Chrome Bookmarks only),
          # etc. Multiple types can be strung together: !hshcb (Safari
          # History and Chrome bookmarks).
          history_types:
          - safari_bookmarks
          - safari_history
          # - chrome_history
          # - chrome_bookmarks
          # - firefox_bookmarks
          # - firefox_history
          # - edge_bookmarks
          # - edge_history
          # - brave_bookmarks
          # - brave_history
          # - arc_history
          # - arc_bookmarks
          # Pinboard search
          # You can find your api key here: https://pinboard.in/settings/password
          pinboard_api_key: ''
          # Generate an access token at https://app.bitly.com/settings/api/
          bitly_access_token: ''
          bitly_domain: 'bit.ly'

        ENDCONFIG

        File.open(File.expand_path('~/.searchlink'), 'w') do |f|
          f.puts default_config
        end
      end

      config = YAML.load_file(File.expand_path('~/.searchlink'))

      # set to true to have an HTML comment inserted showing any errors
      config['debug'] ||= false

      # set to true to get a verbose report at the end of multi-line processing
      config['report'] ||= false

      config['backup'] = true unless config.key? 'backup'

      config['timeout'] ||= 15

      # set to true to force inline links
      config['inline'] ||= false

      # set to true to add titles to links based on site title
      config['include_titles'] ||= false

      # set to true to remove SEO elements from page titles
      config['remove_seo'] ||= false

      # set to true to use page title as link text when empty
      config['empty_uses_page_title'] ||= false

      # change this to set a specific country for search (default US)
      config['country_code'] ||= 'US'

      # set to true to include a random string in ref titles
      # allows running SearchLink multiple times w/out conflicts
      config['prefix_random'] = false unless config['prefix_random']

      config['social_template'] ||= '%service%/%user%'

      # append affiliate link info to iTunes urls, empty quotes for none
      # example:
      # $itunes_affiliate = "&at=10l4tL&ct=searchlink"
      config['itunes_affiliate'] ||= '&at=10l4tL&ct=searchlink'

      # to create Amazon affiliate links, set amazon_partner to your amazon
      # affiliate tag
      #    amazon_partner: "bretttercom-20"
      config['amazon_partner'] ||= ''

      # To create custom abbreviations for Google Site Searches,
      # add to (or replace) the hash below.
      # "abbreviation" => "site.url",
      # This allows you, for example to use [search term](!bt)
      # as a shortcut to search brettterpstra.com. Keys in this
      # hash can override existing search triggers.
      config['custom_site_searches'] ||= {
        'bt' => 'brettterpstra.com',
        'imdb' => 'imdb.com'
      }

      # confirm existence of links generated from custom search replacements
      config['validate_links'] ||= false

      # use notification center to show progress
      config['notifications'] ||= false
      config['pinboard_api_key'] ||= false

      SL.line_num = nil
      SL.match_column = nil
      SL.match_length = nil
      SL.config = config
    end

    def restore_prev_config
      @prev_config&.each do |k, v|
        SL.config[k] = v
        $stderr.print "\r\033[0KReset config: #{k} = #{SL.config[k]}\n" unless SILENT
      end
      @prev_config = {}
    end
  end
end

module SL
  module Searches
    class << self
      def plugins
        @plugins ||= {}
      end

      def load_searches
        Dir.glob(File.join(File.dirname(__FILE__), 'searches', '*.rb')).sort.each { |f| require f }
      end

      #
      # Register a plugin with the plugin manager
      #
      # @param [String, Array] title title or array of titles
      # @param [Symbol] type plugin type (:search)
      # @param [Class] klass class that handles plugin actions. Search plugins 
      #                must have a #settings and a #search method
      #
      def register(title, type, klass)
        Array(title).each { |t| register_plugin(t, type, klass) }
      end

      def description_for_search(search_type)
        description = "#{search_type} search"
        plugins[:search].each do |_, plugin|
          s = plugin[:searches].select { |s| s[0] == search_type }
          unless s.empty?
            description = s[0][1]
            break
          end
        end
        description
      end

      #
      # Output an HTML table of available searches
      #
      # @return [String] Table HTML
      #
      def available_searches_html
        searches = plugins[:search]
                   .flat_map { |_, plugin| plugin[:searches] }
                   .reject { |s| s[1].nil? }
                   .sort_by { |s| s[0] }
        out = ['<table id="searches">',
               '<thead><td>Shortcut</td><td>Search Type</td></thead>',
               '<tbody>']
        searches.each { |s| out << "<tr><td><code>!#{s[0]}</code></td><td>#{s[1]}</td></tr>" }
        out.concat(['</tbody>', '</table>']).join("\n")
      end

      #
      # Aligned list of available searches
      #
      # @return [String] Aligned list of searches
      #
      def available_searches
        searches = []
        plugins[:search].each { |_, plugin| searches.concat(plugin[:searches].delete_if { |s| s[1].nil? }) }
        out = ''
        searches.each { |s| out += "!#{s[0]}#{s[0].spacer}#{s[1]}\n" }
        out
      end

      def best_search_match(term)
        searches = all_possible_searches.dup
        searches.select { |s| s.matches_score(term, separator: '', start_word: false) > 8 }
      end

      def all_possible_searches
        searches = []
        plugins[:search].each { |_, plugin| plugin[:searches].each { |s| searches.push(s[0]) } }
        searches.concat(SL.config['custom_site_searches'].keys)
      end

      def did_you_mean(term)
        matches = best_search_match(term)
        matches.empty? ? '' : ", did you mean #{matches.map { |m| "!#{m}" }.join(', ')}?"
      end

      def valid_searches
        searches = []
        plugins[:search].each { |_, plugin| searches.push(plugin[:trigger]) }
        searches
      end

      def valid_search?(term)
        valid = false
        valid = true if term =~ /^(#{valid_searches.join('|')})$/
        valid = true if SL.config['custom_site_searches'].keys.include? term
        # SL.notify("Invalid search#{did_you_mean(term)}", term) unless valid
        valid
      end

      def register_plugin(title, type, klass)
        raise StandardError, "Plugin #{title} has no settings method" unless klass.respond_to? :settings

        settings = klass.settings

        raise StandardError, "Plugin #{title} has no search method" unless klass.respond_to? :search

        plugins[type] ||= {}
        plugins[type][title] = {
          trigger: settings.fetch(:trigger, title).normalize_trigger,
          searches: settings[:searches],
          class: klass
        }
      end

      def load_custom
        plugins_folder = File.expand_path('~/.local/searchlink/plugins')
        return unless File.directory?(plugins_folder)

        Dir.glob(File.join(plugins_folder, '**/*.rb')).sort.each do |plugin|
          require plugin
        end
      end

      def do_search(search_type, search_terms, link_text, timeout: SL.config['timeout'])
        plugins[:search].each do |_title, plugin|
          if search_type =~ /^#{plugin[:trigger]}$/
            search = proc { plugin[:class].search(search_type, search_terms, link_text) }
            return SL::Util.search_with_timeout(search, timeout)
          end
        end
      end
    end
  end
end

# title: Apple Music Search
# description: Search Apple Music
module SL
  # Apple Music Search
  class AppleMusicSearch
    class << self
      def settings
        {
          trigger: 'am(pod|art|alb|song)?e?',
          searches: [
            ['am', 'Apple Music'],
            ['ampod', 'Apple Music Podcast'],
            ['amart', 'Apple Music Artist'],
            ['amalb', 'Apple Music Album'],
            ['amsong', 'Apple Music Song'],
            ['amalbe', 'Apple Music Album Embed'],
            ['amsong', 'Apple Music Song Embed']
          ]
        }
      end

      def search(search_type, search_terms, link_text)
        stype = search_type.downcase.sub(/^am/, '')
        otype = :link
        if stype =~ /e$/
          otype = :embed
          stype.sub!(/e$/, '')
        end
        result = case stype
                 when /^pod$/
                   applemusic(search_terms, 'podcast')
                 when /^art$/
                   applemusic(search_terms, 'music', 'musicArtist')
                 when /^alb$/
                   applemusic(search_terms, 'music', 'album')
                 when /^song$/
                   applemusic(search_terms, 'music', 'musicTrack')
                 else
                   applemusic(search_terms)
                 end

        return [false, "Not found: #{search_terms}", link_text] unless result

        # {:type=>,:id=>,:url=>,:title=>}
        if otype == :embed && result[:type] =~ /(album|song)/
          url = 'embed'
          if result[:type] =~ /song/
            link = %(https://embed.music.apple.com/#{SL.config['country_code'].downcase}/album/#{result[:album]}?i=#{result[:id]}&app=music#{SL.config['itunes_affiliate']})
            height = 150
          else
            link = %(https://embed.music.apple.com/#{SL.config['country_code'].downcase}/album/#{result[:id]}?app=music#{SL.config['itunes_affiliate']})
            height = 450
          end

          title = [
            %(<iframe src="#{link}" allow="autoplay *; encrypted-media *;"),
            %(frameborder="0" height="#{height}"),
            %(style="width:100%;max-width:660px;overflow:hidden;background:transparent;"),
            %(sandbox="allow-forms allow-popups allow-same-origin),
            %(allow-scripts allow-top-navigation-by-user-activation"></iframe>)
          ].join(' ')
        else
          url = result[:url]
          title = result[:title]
        end
        [url, title, link_text]
      end

      # Search apple music
      # terms => search terms (unescaped)
      # media => music, podcast
      # entity => optional: artist, song, album, podcast
      # returns {:type=>,:id=>,:url=>,:title}
      def applemusic(terms, media = 'music', entity = '')
        url = URI.parse("http://itunes.apple.com/search?term=#{terms.url_encode}&country=#{SL.config['country_code']}&media=#{media}&entity=#{entity}")
        res = Net::HTTP.get_response(url).body
        res = res.force_encoding('utf-8') if RUBY_VERSION.to_f > 1.9
        res.gsub!(/(?mi)[\x00-\x08\x0B-\x0C\x0E-\x1F]/, '')
        json = JSON.parse(res)
        return false unless json['resultCount']&.positive?

        output = process_result(json['results'][0])

        return false if output.empty?

        output
      end

      def process_result(result)
        output = {}
        aff = SL.config['itunes_affiliate']

        case result['wrapperType']
        when 'track'
          if result['kind'] == 'podcast'
            output[:type] = 'podcast'
            output[:id] = result['collectionId']
            output[:url] = result['collectionViewUrl'].to_am + aff
            output[:title] = result['collectionName']
          else
            output[:type] = 'song'
            output[:album] = result['collectionId']
            output[:id] = result['trackId']
            output[:url] = result['trackViewUrl'].to_am + aff
            output[:title] = "#{result['trackName']} by #{result['artistName']}"
          end
        when 'collection'
          output[:type] = 'album'
          output[:id] = result['collectionId']
          output[:url] = result['collectionViewUrl'].to_am + aff
          output[:title] = "#{result['collectionName']} by #{result['artistName']}"
        when 'artist'
          output[:type] = 'artist'
          output[:id] = result['artistId']
          output[:url] = result['artistLinkUrl'].to_am + aff
          output[:title] = result['artistName']
        end

        output
      end
    end

    SL::Searches.register 'applemusic', :search, self
  end
end

# title: iTunes Search
# description: Search iTunes
module SL
  class ITunesSearch
    class << self
      def settings
        {
          trigger: '(i(pod|art|alb|song|tud?)|masd?)',
          searches: [
            ['ipod', 'iTunes podcast'],
            ['iart', 'iTunes artist'],
            ['ialb', 'iTunes album'],
            ['isong', 'iTunes song'],
            ['itu', 'iOS App Store Search'],
            ['itud', 'iOS App Store Developer Link'],
            ['mas', 'Mac App Store Search'],
            ['masd', 'Mac App Store Developer Link']
          ]
        }
      end

      def search(search_type, search_terms, link_text)
        case search_type
        when /^ialb$/ # iTunes Album Search
          url, title = search_itunes('album', search_terms, false)
        when /^iart$/ # iTunes Artist Search
          url, title = search_itunes('musicArtist', search_terms, false)
        when /^imov?$/ # iTunes movie search
          dev = false
          url, title = search_itunes('movie', search_terms, dev, SL.config['itunes_affiliate'])
        when /^ipod$/
          url, title = search_itunes('podcast', search_terms, false)
        when /^isong$/ # iTunes Song Search
          url, title = search_itunes('song', search_terms, false)
        when /^itud?$/ # iTunes app search
          dev = search_type =~ /d$/
          url, title = search_itunes('iPadSoftware', search_terms, dev, SL.config['itunes_affiliate'])
        when /^masd?$/ # Mac App Store search (mas = itunes link, masd = developer link)
          dev = search_type =~ /d$/
          url, title = search_itunes('macSoftware', search_terms, dev, SL.config['itunes_affiliate'])
        end

        [url, title, link_text]
      end

      def search_itunes(entity, terms, dev, aff = nil)
        aff ||= SL.config['itunes_affiliate']

        url = URI.parse("http://itunes.apple.com/search?term=#{terms.url_encode}&country=#{SL.config['country_code']}&entity=#{entity}&limit=1")

        res = Net::HTTP.get_response(url).body
        res = res.force_encoding('utf-8').encode # if RUBY_VERSION.to_f > 1.9

        begin
          json = JSON.parse(res)
        rescue StandardError => e
          SL.add_error('Invalid response', "Search for #{terms}: (#{e})")
          return false
        end
        return false unless json

        return false unless json['resultCount']&.positive?

        result = json['results'][0]
        case entity
        when /movie/
          # dev parameter probably not necessary in this case
          output_url = result['trackViewUrl']
          output_title = result['trackName']
        when /(mac|iPad)Software/
          output_url = dev && result['sellerUrl'] ? result['sellerUrl'] : result['trackViewUrl']
          output_title = result['trackName']
        when /(musicArtist|song|album)/
          case result['wrapperType']
          when 'track'
            output_url = result['trackViewUrl']
            output_title = "#{result['trackName']} by #{result['artistName']}"
          when 'collection'
            output_url = result['collectionViewUrl']
            output_title = "#{result['collectionName']} by #{result['artistName']}"
          when 'artist'
            output_url = result['artistLinkUrl']
            output_title = result['artistName']
          end
        when /podcast/
          output_url = result['collectionViewUrl']
          output_title = result['collectionName']
        end
        return false unless output_url && output_title

        return [output_url, output_title] if dev

        [output_url + aff, output_title]
      end
    end

    SL::Searches.register 'itunes', :search, self
  end
end

module SL
  # Amazon Search
  class AmazonSearch
    class << self
      def settings
        {
          trigger: 'a',
          searches: [
            ['a', 'Amazon Search']
          ]
        }
      end

      def search(_, search_terms, link_text)
        az_url, = SL.ddg("site:amazon.com #{search_terms}", link_text)
        url, title = SL::URL.amazon_affiliatize(az_url, SL.config['amazon_partner'])
        title ||= search_terms

        [url, title, link_text]
      end
    end

    SL::Searches.register 'amazon', :search, self
  end
end

module SL
  # Bit.ly link shortening
  class BitlySearch
    class << self
      def settings
        {
          trigger: 'b(l|itly)',
          searches: [
            ['bl', 'bit.ly Shorten'],
            ['bitly', 'bit.ly shorten']
          ]
        }
      end

      def search(_, search_terms, link_text)
        if SL::URL.url?(search_terms)
          link = search_terms
        else
          link, rtitle = SL.ddg(search_terms, link_text)
        end

        url, title = bitly_shorten(link, rtitle)
        link_text = title || url
        [url, title, link_text]
      end

      def bitly_shorten(url, title = nil)
        unless SL.config.key?('bitly_access_token') && !SL.config['bitly_access_token'].empty?
          SL.add_error('Bit.ly not configured', 'Missing access token')
          return [false, title]
        end

        domain = SL.config.key?('bitly_domain') ? SL.config['bitly_domain'] : 'bit.ly'
        long_url = url.dup
        cmd = [
          %(curl -SsL -H 'Authorization: Bearer #{SL.config['bitly_access_token']}'),
          %(-H 'Content-Type: application/json'),
          '-X POST', %(-d '{ "long_url": "#{url}", "domain": "#{domain}" }'), 'https://api-ssl.bitly.com/v4/shorten'
        ]
        data = JSON.parse(`#{cmd.join(' ')}`.strip)
        link = data['link']
        title ||= SL::URL.get_title(long_url)
        [link, title]
      end
    end

    SL::Searches.register 'bitly', :search, self
  end
end

module SL
  # Dictionary Definition Search
  class DefinitionSearch
    class << self
      # Returns a hash of settings for the search
      #
      # @return     [Hash] the settings for the search
      #
      def settings
        {
          trigger: 'def(?:ine)?',
          searches: [
            ['def', 'Dictionary Definition'],
            ['define', nil]
          ]
        }
      end

      # Searches for a definition of the given terms
      #
      # @param      _             [String] unused
      # @param      search_terms  [String] the terms to
      #                           search for
      # @param      link_text     [String] the text to use
      #                           for the link
      # @return     [Array] the url, title, and link text for the
      #             search
      #
      def search(_, search_terms, link_text)
        fix = SL.spell(search_terms)

        if fix && search_terms.downcase != fix.downcase
          SL.add_error('Spelling', "Spelling altered for '#{search_terms}' to '#{fix}'")
          search_terms = fix
          link_text = fix
        end

        url, title = define(search_terms)

        url ? [url, title, link_text] : [false, false, link_text]
      end

      # Searches for a definition of the given terms
      #
      # @param      terms  [String] the terms to search for
      # @return     [Array] the url and title for the search
      #
      def define(terms)
        def_url = "https://www.wordnik.com/words/#{terms.url_encode}"
        body = `/usr/bin/curl -sSL '#{def_url}'`
        if body =~ /id="define"/
          first_definition = body.match(%r{(?mi)(?:id="define"[\s\S]*?<li>)([\s\S]*?)</li>})[1]
          parts = first_definition.match(%r{<abbr title="partOfSpeech">(.*?)</abbr> (.*?)$})
          return [def_url, "(#{parts[1]}) #{parts[2]}".gsub(%r{</?.*?>}, '').strip]
        end

        false
      rescue StandardError
        false
      end
    end

    # Registers the search with the SL::Searches module
    SL::Searches.register 'definition', :search, self
  end
end

module SL
  # DuckDuckGo Search
  class DuckDuckGoSearch
    class << self
      # Returns a hash of settings for the DuckDuckGoSearch
      # class
      #
      # @return     [Hash] settings for the DuckDuckGoSearch
      #             class
      #
      def settings
        {
          trigger: '(?:g|ddg|z)',
          searches: [
            ['g', 'DuckDuckGo Search'],
            ['ddg', 'DuckDuckGo Search'],
            ['z', 'DDG Zero Click Search']
          ]
        }
      end

      # Searches DuckDuckGo for the given search terms
      #
      # @param      search_type   [String] the type of
      #                           search to perform
      # @param      search_terms  [String] the terms to
      #                           search for
      # @param      link_text     [String] the text to
      #                           display for the link
      # @return     [Array] an array containing the URL, title, and
      #             link text
      #
      def search(search_type, search_terms, link_text)
        return zero_click(search_terms, link_text) if search_type =~ /^z$/

        begin
          terms = "%5C#{search_terms.url_encode}"
          body = `/usr/bin/curl -LisS --compressed 'https://lite.duckduckgo.com/lite/?q=#{terms}' 2>/dev/null`

          locs = body.force_encoding('utf-8').scan(/^location: (.*?)$/)
          return false if locs.empty?

          url = locs[-1]

          result = url[0].strip || false
          return false unless result

          return false if result =~ /internal-search\.duckduckgo\.com/

          # output_url = CGI.unescape(result)
          output_url = result

          output_title = if SL.config['include_titles'] || SL.titleize
                           SL::URL.get_title(output_url) || ''
                         else
                           ''
                         end

          [output_url, output_title, link_text]
        end
      end

      # Searches DuckDuckGo for the given search terms and
      # returns a zero click result
      #
      # @param      search_terms  [String] the terms to
      #                           search for
      # @param      link_text     [String] the text to
      #                           display for the link
      # @param      disambiguate  [Boolean] whether to
      #                           disambiguate the search
      #
      # @return     [Array] an array containing the URL,
      #             title, and link text
      #
      def zero_click(search_terms, link_text, disambiguate: false)
        search_terms.gsub!(/%22/, '"')
        d = disambiguate ? '0' : '1'
        url = URI.parse("http://api.duckduckgo.com/?q=#{search_terms.url_encode}&format=json&no_redirect=1&no_html=1&skip_disambig=#{d}")
        res = Net::HTTP.get_response(url).body
        res = res.force_encoding('utf-8') if RUBY_VERSION.to_f > 1.9

        result = JSON.parse(res)
        return search('ddg', terms, link_text) unless result

        wiki_link = result['AbstractURL'] || result['Redirect']
        title = result['Heading'] || false

        if !wiki_link.empty? && !title.empty?
          [wiki_link, title, link_text]
        elsif disambiguate
          search('ddg', search_terms, link_text)
        else
          zero_click(search_terms, link_text, disambiguate: true)
        end
      end
    end

    # Registers the DuckDuckGoSearch class with the Searches
    # module
    # @param      name   [String] the name of the search
    # @param      type   [Symbol] the type of search to
    #                    perform
    # @param      klass  [Class] the class to register
    SL::Searches.register 'duckduckgo', :search, self
  end
end

# SL module methods
module SL
  class << self
    # Performs a DuckDuckGo search with the given search
    # terms and link text. If link text is not provided, the
    # first result will be returned. The search will timeout
    # after the given number of seconds.
    #
    # @param      search_terms  [String] The search terms to
    #                           use
    # @param      link_text     [String] The text of the
    #                           link to search for
    # @param      timeout       [Integer] The timeout for
    #                           the search in seconds
    # @return     [SL::Searches::Result] The search result
    #
    def ddg(search_terms, link_text = nil, timeout: SL.config['timeout'])
      search = proc { SL::Searches.plugins[:search]['duckduckgo'][:class].search('ddg', search_terms, link_text) }
      SL::Util.search_with_timeout(search, timeout)
    end
  end
end

module SL
  # GitHub search
  class GitHubSearch
    class << self
      def settings
        {
          trigger: '(?:giste?|ghu?)',
          searches: [
            ['gh', 'GitHub User/Repo Link'],
            ['ghu', 'GitHub User Search'],
            ['gist', 'Gist Search'],
            ['giste', 'Gist Embed']
          ]
        }
      end

      def search(search_type, search_terms, link_text)
        case search_type
        when /^gist/
          url, title, link_text = gist(search_terms, search_type, link_text)
        when /^ghu$/
          url, title, link_text = github_user(search_terms, link_text)
        else
          url, title, link_text = github(search_terms, link_text)
        end

        link_text = title if link_text == '' || link_text == search_terms

        [url, title, link_text]
      end

      def github_search_curl(endpoint, query)
        auth = Secrets::GH_AUTH_TOKEN ? "Authorization: Bearer #{Secrets::GH_AUTH_TOKEN}" : ''

        headers = [
          'Accept: application/vnd.github+json',
          'X-GitHub-Api-Version: 2022-11-28',
          auth
        ]

        url = "https://api.github.com/search/#{endpoint}?q=#{query.url_encode}&per_page=1&page=1&order=desc"

        res = JSON.parse(`curl -SsL #{headers.map { |h| %(-H "#{h}") }.join(' ')} #{url}`)

        if res.key?('total_count') && res['total_count'].positive?
          res['items'][0]
        else
          false
        end
      end

      def user_gists(user, search_terms, page = 1)
        auth = Secrets::GH_AUTH_TOKEN ? "Authorization: Bearer #{Secrets::GH_AUTH_TOKEN}" : ''

        headers = [
          'Accept: application/vnd.github+json',
          'X-GitHub-Api-Version: 2022-11-28',
          auth
        ]

        url = "https://api.github.com/users/#{user}/gists?per_page=100&page=#{page}"

        res = JSON.parse(`curl -SsL #{headers.map { |h| %(-H "#{h}") }.join(' ')} '#{url}'`)

        best = nil
        best = filter_gists(res, search_terms) if res

        if !best && res.count == 100
          SL.notify('Paging', "Getting page #{page + 1} of #{user} gists")
          best = user_gists(user, search_terms, page + 1)
        end

        best
      end

      def github(search_terms, link_text)
        terms = search_terms.split(%r{[ /]+})
        # SL.config['remove_seo'] = false

        url = case terms.count
              when 2
                "https://github.com/#{terms[0]}/#{terms[1]}"
              when 1
                "https://github.com/#{terms[0]}"
              else
                nurl, title, link_text = SL.ddg("site:github.com #{search_terms}", link_text)
                nurl
              end

        if SL::URL.valid_link?(url)
          title = SL::URL.get_title(url) if url && title.nil?

          [url, title, link_text]
        else
          SL.notify('Searching GitHub', 'Repo not found, performing search')
          search_github(search_terms, link_text)
        end
      end

      def github_user(search_terms, link_text)
        if search_terms.split(/ /).count > 1
          query = %(#{search_terms} in:name)
          res = github_search_curl('users', query)
        else
          query = %(user:#{search_terms})
          res = github_search_curl('users', query)
          res ||= github_search_curl('users', search_terms)
        end

        if res
          url = res['html_url']
          title = res['login']

          [url, title, link_text]
        else
          [false, false, link_text]
        end
      end

      def search_github(search_terms, link_text)
        search_terms.gsub!(%r{(\S+)/(\S+)}, 'user:\1 \2')
        search_terms.gsub!(/\bu\w*:(\w+)/, 'user:\1')
        search_terms.gsub!(/\bl\w*:(\w+)/, 'language:\1')
        search_terms.gsub!(/\bin?:r\w*/, 'in:readme')
        search_terms.gsub!(/\bin?:t\w*/, 'in:topics')
        search_terms.gsub!(/\bin?:d\w*/, 'in:description')
        search_terms.gsub!(/\bin?:(t(itle)?|n(ame)?)/, 'in:name')
        search_terms.gsub!(/\br:/, 'repo:')

        search_terms += ' in:title' unless search_terms =~ /(in|user|repo):/

        res = github_search_curl('repositories', search_terms)

        return false unless res

        url = res['html_url']
        title = res['description'] || res['full_name']
        [url, title, link_text]
      end

      def search_user_gists(user, search_terms)
        best_gist = user_gists(user, search_terms, 1)

        return false unless best_gist

        best_gist
      end

      def filter_gists(gists, search_terms)
        score = 0
        gists.map! do |g|
          {
            url: g['html_url'],
            description: g['description'],
            files: g['files'].map { |file, info| { filename: file, raw: info['raw_url'] } }
          }
        end
        matches = []
        gists.each do |g|
          if g.key?(:files)
            g[:files].each do |f|
              next unless f[:filename]

              score = f[:filename].matches_score(search_terms.gsub(/[^a-z0-9]/, ' '))

              if score > 5
                url = "#{g[:url]}#file-#{f[:filename].gsub(/\./, '-')}"
                matches << { url: url, title: f[:filename], score: score }
              end
            end
          end

          score = g[:description].nil? ? 0 : g[:description].matches_score(search_terms.gsub(/[^a-z0-9]/, ' '))
          matches << { url: g[:url], title: g[:files][0][:filename], score: score } if score > 5
        end

        return false if matches.empty?

        matches.max_by { |m| m[:score] }
      end

      def gist(terms, type, link_text)
        terms.strip!
        case terms
        # If an id (and optional file) are given, expand it to include username an generate link
        when %r{^(?<id>[a-z0-9]{32}|[0-9]{6,10})(?:[#/](?<file>(?:file-)?.*?))?$}
          m = Regexp.last_match
          res = `curl -SsLI 'https://gist.github.com/#{m['id']}'`.strip
          url = res.match(/^location: (.*?)$/)[1].strip
          title = SL::URL.get_title(url)

          url = "#{url}##{m['file']}" if m['file']
        # If a user an id (an o) are given, convert to a link
        when %r{^(?<u>\w+)/(?<id>[a-z0-9]{32}|[0-9]{6,10})(?:[#/](?<file>(?:file-)?.*?))?$}
          m = Regexp.last_match
          url = "https://gist.github.com/#{m['u']}/#{m['id']}"
          title = SL::URL.get_title(url)

          url = "#{url}##{m['file']}" if m['file']
        # if a full gist URL is given, simply clean it up
        when %r{(?<url>https://gist.github.com/(?:(?<user>\w+)/)?(?<id>[a-z0-9]{32}|[0-9]{6,10}))(?:[#/](?<file>(?:file-)?.*?))?$}
          m = Regexp.last_match
          url = m['url']
          title = SL::URL.get_title(url)

          url = "#{url}##{m['file']}" if m['file']
        # Otherwise do a search of gist.github.com for the keywords
        else
          if terms.split(/ +/).count > 1
            parts = terms.split(/ +/)
            gist = search_user_gists(parts[0], parts[1..].join(' '))

            if gist
              url = gist[:url]
              title = gist[:title]
            else
              url, title, link_text = SL.ddg("site:gist.github.com #{terms}", link_text)
            end
          else
            url, title, link_text = SL.ddg("site:gist.github.com #{terms}", link_text)
          end
        end

        # Assuming we retrieved a full gist URL
        if url =~ %r{https://gist.github.com/(?:(?<user>[^/]+)/)?(?<id>[a-z0-9]+?)(?:[#/](?<file>(?:file-)?.*?))?$}
          m = Regexp.last_match
          user = m['user']
          id = m['id']

          # If we're trying to create an embed, convert elements to a JS embed script
          if type =~ /e$/
            url = if m['file']
                    "https://gist.github.com/#{user}/#{id}.js?file=#{m['file'].fix_gist_file}"
                  else
                    "https://gist.github.com/#{user}/#{id}.js"
                  end

            ['embed', %(<script src="#{url}"></script>), link_text]
          else
            [url, title, link_text]
          end
        else
          [false, title, link_text]
        end
      end
    end

    SL::Searches.register 'github', :search, self
  end
end

##
## Chromium (Chrome, Arc, Brave, Edge) search methods
##
module SL
  # Chromium history search
  class HistorySearch
    class << self
      ## Search Arc history
      ##
      ## @param      term  The search term
      ##
      ## @return     [Array] Single bookmark, [url, title, date]
      ##
      def search_arc_history(term)
        # Google history
        history_file = File.expand_path('~/Library/Application Support/Arc/User Data/Default/History')
        if File.exist?(history_file)
          SL.notify('Searching Arc History', term)
          search_chromium_history(history_file, term)
        else
          false
        end
      end

      ## Search Brave history
      ##
      ## @param      term  The search term
      ##
      ## @return     [Array] Single bookmark, [url, title, date]
      ##
      def search_brave_history(term)
        # Google history
        history_file = File.expand_path('~/Library/Application Support/BraveSoftware/Brave-Browser/Default/History')
        if File.exist?(history_file)
          SL.notify('Searching Brave History', term)
          search_chromium_history(history_file, term)
        else
          false
        end
      end

      ## Search Edge history
      ##
      ## @param      term  The search term
      ##
      ## @return     [Array] Single bookmark, [url, title, date]
      ##
      def search_edge_history(term)
        # Google history
        history_file = File.expand_path('~/Library/Application Support/Microsoft Edge/Default/History')
        if File.exist?(history_file)
          SL.notify('Searching Edge History', term)
          search_chromium_history(history_file, term)
        else
          false
        end
      end

      ## Search Chrome history
      ##
      ## @param      term  The search term
      ##
      ## @return     [Array] Single bookmark, [url, title, date]
      ##
      def search_chrome_history(term)
        # Google history
        history_file = File.expand_path('~/Library/Application Support/Google/Chrome/Default/History')
        if File.exist?(history_file)
          SL.notify('Searching Chrome History', term)
          search_chromium_history(history_file, term)
        else
          false
        end
      end

      ##
      ## Generic chromium history search
      ##
      ## @param      history_file  [String] The history file
      ##                           path for the selected
      ##                           browser
      ## @param      term          [String] The search term
      ##
      ## @return     [Array] Single bookmark, [url, title, date]
      ##
      def search_chromium_history(history_file, term)
        tmpfile = "#{history_file}.tmp"
        FileUtils.cp(history_file, tmpfile)

        exact_match = false
        match_phrases = []

        # If search terms start with ''term, only search for exact string matches
        if term =~ /^ *'/
          exact_match = true
          term.gsub!(/(^ *'+|'+ *$)/, '')
        elsif term =~ /%22(.*?)%22/
          match_phrases = term.scan(/%22(\S.*?\S)%22/)
          term.gsub!(/%22(\S.*?\S)%22/, '')
        end

        terms = []
        terms.push("(url NOT LIKE '%search/?%'
                   AND url NOT LIKE '%?q=%'
                   AND url NOT LIKE '%?s=%'
                   AND url NOT LIKE '%duckduckgo.com/?t%')")
        if exact_match
          terms.push("(url LIKE '%#{term.strip.downcase}%' OR title LIKE '%#{term.strip.downcase}%')")
        else
          terms.concat(term.split(/\s+/).map do |t|
            "(url LIKE '%#{t.strip.downcase}%' OR title LIKE '%#{t.strip.downcase}%')"
          end)
          terms.concat(match_phrases.map do |t|
            "(url LIKE '%#{t[0].strip.downcase}%' OR title LIKE '%#{t[0].strip.downcase}%')"
          end)
        end

        query = terms.join(' AND ')
        most_recent = `sqlite3 -json '#{tmpfile}' "select title, url,
        datetime(last_visit_time / 1000000 + (strftime('%s', '1601-01-01')), 'unixepoch') as datum
        from urls where #{query} order by datum desc limit 1 COLLATE NOCASE;"`.strip
        FileUtils.rm_f(tmpfile)
        return false if most_recent.strip.empty?

        bm = JSON.parse(most_recent)[0]

        date = Time.parse(bm['datum'])
        [bm['url'], bm['title'], date]
      end

      ##
      ## Search Arc bookmarks
      ##
      ## @param      term  [String] The search term
      ##
      ## @return     [Array] single bookmark [url, title, date]
      ##
      def search_arc_bookmarks(term)
        bookmarks_file = File.expand_path('~/Library/Application Support/Arc/User Data/Default/Bookmarks')

        if File.exist?(bookmarks_file)
          SL.notify('Searching Brave Bookmarks', term)
          return search_chromium_bookmarks(bookmarks_file, term)
        end

        false
      end

      ##
      ## Search Brave bookmarks
      ##
      ## @param      term  [String] The search term
      ##
      ## @return     [Array] single bookmark [url, title, date]
      ##
      def search_brave_bookmarks(term)
        bookmarks_file = File.expand_path('~/Library/Application Support/BraveSoftware/Brave-Browser/Default/Bookmarks')

        if File.exist?(bookmarks_file)
          SL.notify('Searching Brave Bookmarks', term)
          return search_chromium_bookmarks(bookmarks_file, term)
        end

        false
      end

      ##
      ## Search Ege bookmarks
      ##
      ## @param      term  [String] The search term
      ##
      ## @return     [Array] single bookmark [url, title, date]
      ##
      def search_edge_bookmarks(term)
        bookmarks_file = File.expand_path('~/Library/Application Support/Microsoft Edge/Default/Bookmarks')

        if File.exist?(bookmarks_file)
          SL.notify('Searching Edge Bookmarks', term)
          return search_chromium_bookmarks(bookmarks_file, term)
        end

        false
      end

      ##
      ## Search Chrome bookmarks
      ##
      ## @param      term  [String] The search term
      ##
      ## @return     [Array] single bookmark [url, title, date]
      ##
      def search_chrome_bookmarks(term)
        bookmarks_file = File.expand_path('~/Library/Application Support/Google/Chrome/Default/Bookmarks')

        if File.exist?(bookmarks_file)
          SL.notify('Searching Chrome Bookmarks', term)
          return search_chromium_bookmarks(bookmarks_file, term)
        end

        false
      end

      ##
      ## Generic chromium bookmark search
      ##
      ## @param      bookmarks_file  [String] The path to
      ##                             bookmarks file for
      ##                             selected browser
      ## @param      term            [String] The term
      ##
      ## @return     [Array] single bookmark [url, title, date]
      ##
      def search_chromium_bookmarks(bookmarks_file, term)
        chrome_bookmarks = JSON.parse(IO.read(bookmarks_file))

        exact_match = false
        match_phrases = []

        # If search terms start with ''term, only search for exact string matches
        if term =~ /^ *'/
          exact_match = true
          term.gsub!(/(^ *'+|'+ *$)/, '')
        elsif term =~ /%22(.*?)%22/
          match_phrases = term.scan(/%22(\S.*?\S)%22/)
          term.gsub!(/%22(\S.*?\S)%22/, '')
        end

        if chrome_bookmarks
          roots = chrome_bookmarks['roots']

          urls = extract_chrome_bookmarks(roots, [], term)

          unless urls.empty?
            urls.delete_if { |bm| !(bm[:url].matches_exact(term) || bm[:title].matches_exact(term)) } if exact_match

            if match_phrases
              match_phrases.map! { |phrase| phrase[0] }
              urls.delete_if do |bm|
                matched = true
                match_phrases.each do |phrase|
                  matched = false unless bm[:url].matches_exact(phrase) || bm[:title].matches_exact(phrase)
                end
                !matched
              end
            end

            return false if urls.empty?

            lastest_bookmark = urls.max_by { |u| u[:score] }

            return [lastest_bookmark[:url], lastest_bookmark[:title], lastest_bookmark[:date]]
          end
        end

        false
      end

      ##
      ## Extract chromium bookmarks from JSON file
      ##
      ## @param      json  [String] The json data
      ## @param      urls  [Array] The gathered urls,
      ##                   appended to recursively
      ## @param      term  [String] The search term
      ##                   (optional)
      ##
      ## @return [Array] array of bookmarks
      ##
      def extract_chrome_bookmarks(json, urls = [], term = '')
        if json.instance_of?(Array)
          json.each { |item| urls = extract_chrome_bookmarks(item, urls, term) }
        elsif json.instance_of?(Hash)
          if json.key? 'children'
            urls = extract_chrome_bookmarks(json['children'], urls, term)
          elsif json['type'] == 'url'
            date = Time.at(json['date_added'].to_i / 1000000 + (Time.new(1601, 01, 01).strftime('%s').to_i))
            url = { url: json['url'], title: json['name'], date: date }
            score = score_mark(url, term)

            if score > 7
              url[:score] = score
              urls << url
            end
          else
            json.each { |_, v| urls = extract_chrome_bookmarks(v, urls, term) }
          end
        else
          return urls
        end
        urls
      end

      ##
      ## Score bookmark for search term matches
      ##
      ## @param      mark   [Hash] The bookmark
      ## @param      terms  [String] The search terms
      ##
      def score_mark(mark, terms)
        return 0 unless mark[:url]

        score = if mark[:title] && mark[:title].matches_exact(terms)
                  12 + mark[:url].matches_score(terms, start_word: false)
                elsif mark[:url].matches_exact(terms)
                  11
                elsif mark[:title] && mark[:title].matches_score(terms) > 5
                  mark[:title].matches_score(terms)
                elsif mark[:url].matches_score(terms, start_word: false)
                  mark[:url].matches_score(terms, start_word: false)
                else
                  0
                end

        score
      end
    end
  end
end

module SL
  class HistorySearch
    class << self
      def search_firefox_history(term)
        # Firefox history
        base = File.expand_path('~/Library/Application Support/Firefox/Profiles')
        Dir.chdir(base)
        profile = Dir.glob('*default-release')
        return false unless profile

        src = File.join(base, profile[0], 'places.sqlite')

        exact_match = false
        match_phrases = []

        # If search terms start with ''term, only search for exact string matches
        case term
        when /^ *'/
          exact_match = true
          term.gsub!(/(^ *'+|'+ *$)/, '')
        when /%22(.*?)%22/
          match_phrases = term.scan(/%22(\S.*?\S)%22/)
          term.gsub!(/%22(\S.*?\S)%22/, '')
        end

        if File.exist?(src)
          SL.notify('Searching Firefox History', term)
          tmpfile = "#{src}.tmp"
          FileUtils.cp(src, tmpfile)

          terms = []
          terms.push("(moz_places.url NOT LIKE '%search/?%'
                     AND moz_places.url NOT LIKE '%?q=%'
                     AND moz_places.url NOT LIKE '%?s=%'
                     AND moz_places.url NOT LIKE '%duckduckgo.com/?t%')")
          if exact_match
            terms.push("(moz_places.url LIKE '%#{term.strip.downcase}%' OR moz_places.title LIKE '%#{term.strip.downcase}%')")
          else
            terms.concat(term.split(/\s+/).map do |t|
              "(moz_places.url LIKE '%#{t.strip.downcase}%' OR moz_places.title LIKE '%#{t.strip.downcase}%')"
            end)
            terms.concat(match_phrases.map do |t|
              "(moz_places.url LIKE '%#{t[0].strip.downcase}%' OR moz_places.title LIKE '%#{t[0].strip.downcase}%')"
            end)
          end
          query = terms.join(' AND ')
          most_recent = `sqlite3 -json '#{tmpfile}' "select moz_places.title, moz_places.url,
          datetime(moz_historyvisits.visit_date/1000000, 'unixepoch', 'localtime') as datum
          from moz_places, moz_historyvisits where moz_places.id = moz_historyvisits.place_id
          and #{query} order by datum desc limit 1 COLLATE NOCASE;"`.strip
          FileUtils.rm_f(tmpfile)

          return false if most_recent.strip.empty?

          marks = JSON.parse(most_recent)

          marks.map! do |bm|
            date = Time.parse(bm['datum'])
            score = score_mark({url: bm['url'], title: bm['title']}, term)
            { url: bm['url'], title: bm['title'], date: date, score: score }
          end


          m = marks.sort_by { |m| [m[:url].length * -1, m[:score]] }.last

          [m[:url], m[:title], m[:date]]
        else
          false
        end
      end

      def search_firefox_bookmarks(term)
        # Firefox history
        base = File.expand_path('~/Library/Application Support/Firefox/Profiles')
        Dir.chdir(base)
        profile = Dir.glob('*default-release')
        return false unless profile

        src = File.join(base, profile[0], 'places.sqlite')

        exact_match = false
        match_phrases = []

        # If search terms start with ''term, only search for exact string matches
        if term =~ /^ *'/
          exact_match = true
          term.gsub!(/(^ *'+|'+ *$)/, '')
        elsif term =~ /%22(.*?)%22/
          match_phrases = term.scan(/%22(\S.*?\S)%22/)
          term.gsub!(/%22(\S.*?\S)%22/, '')
        end

        if File.exist?(src)
          SL.notify('Searching Firefox Bookmarks', term)
          tmpfile = "#{src}.tmp"
          FileUtils.cp(src, tmpfile)

          terms = []
          terms.push("(h.url NOT LIKE '%search/?%'
                     AND h.url NOT LIKE '%?q=%'
                     AND h.url NOT LIKE '%?s=%'
                     AND h.url NOT LIKE '%duckduckgo.com/?t%')")
          if exact_match
            terms.push("(h.url LIKE '%#{term.strip.downcase}%' OR h.title LIKE '%#{term.strip.downcase}%')")
          else
            terms.concat(term.split(/\s+/).map do |t|
              "(h.url LIKE '%#{t.strip.downcase}%' OR h.title LIKE '%#{t.strip.downcase}%')"
            end)
            terms.concat(match_phrases.map do |t|
              "(h.url LIKE '%#{t[0].strip.downcase}%' OR h.title LIKE '%#{t[0].strip.downcase}%')"
            end)
          end

          query = terms.join(' AND ')

          most_recent = `sqlite3 -json '#{tmpfile}' "select h.url, b.title,
          datetime(b.dateAdded/1000000, 'unixepoch', 'localtime') as datum
          FROM moz_places h JOIN moz_bookmarks b ON h.id = b.fk
          where #{query} order by datum desc limit 1 COLLATE NOCASE;"`.strip
          FileUtils.rm_f(tmpfile)

          return false if most_recent.strip.empty?

          bm = JSON.parse(most_recent)[0]

          date = Time.parse(bm['datum'])
          score = score_mark({url: bm['url'], title: bm['title']}, term)
          [bm['url'], bm['title'], date, score]
        else
          false
        end
      end
    end
  end
end

module SL
  class HistorySearch
    class << self
      # Search Safari history for terms
      #
      # @param      term  The search term
      #
      def search_safari_history(term)
        # Safari
        src = File.expand_path('~/Library/Safari/History.db')
        if File.exist?(src)
          SL.notify('Searching Safari History', term)

          exact_match = false
          match_phrases = []

          # If search terms start with ''term, only search for exact string matches
          if term =~ /^ *'/
            exact_match = true
            term.gsub!(/(^ *'+|'+ *$)/, '')
          elsif term =~ /%22(.*?)%22/
            match_phrases = term.scan(/%22(\S.*?\S)%22/)
            term.gsub!(/%22(\S.*?\S)%22/, '')
          end

          terms = []
          terms.push("(url NOT LIKE '%search/?%'
                     AND url NOT LIKE '%?q=%' AND url NOT LIKE '%?s=%'
                     AND url NOT LIKE '%duckduckgo.com/?t%')")
          if exact_match
            terms.push("(url LIKE '%#{term.strip.downcase}%' OR title LIKE '%#{term.strip.downcase}%')")
          else
            terms.concat(term.split(/\s+/).map do |t|
              "(url LIKE '%#{t.strip.downcase}%' OR title LIKE '%#{t.strip.downcase}%')"
            end)
            terms.concat(match_phrases.map do |t|
              "(url LIKE '%#{t[0].strip.downcase}%' OR title LIKE '%#{t[0].strip.downcase}%')"
            end)
          end

          query = terms.join(' AND ')

          cmd = %(sqlite3 -json '#{src}' "select title, url,
          datetime(visit_time/1000000, 'unixepoch', 'localtime') as datum
          from history_visits INNER JOIN history_items ON history_items.id = history_visits.history_item
          where #{query} order by datum desc limit 1 COLLATE NOCASE;")

          most_recent = `#{cmd}`.strip

          return false if most_recent.strip.empty?

          bm = JSON.parse(most_recent)[0]
          date = Time.parse(bm['datum'])
          [bm['url'], bm['title'], date]
        else
          false
        end
      end

      ##
      ## Search Safari bookmarks for relevant search terms
      ##
      ## @param      terms  [String] The search terms
      ##
      ## @return     [Array] [url, title, date]
      ##
      def search_safari_bookmarks(terms)
        data = `plutil -convert xml1 -o - ~/Library/Safari/Bookmarks.plist`.strip
        parent = Plist.parse_xml(data)
        results = get_safari_bookmarks(parent, terms)
        return false if results.empty?

        result = results.max_by { |res| [res[:score], res[:title].length] }

        [result[:url], result[:title], Time.now]
      end

      ##
      ## Score bookmark for search term matches
      ##
      ## @param      mark   [Hash] The bookmark
      ## @param      terms  [String] The search terms
      ##
      def score_bookmark(mark, terms)
        score = if mark[:title].matches_exact(terms)
                  12 + mark[:url].matches_score(terms, start_word: false)
                elsif mark[:url].matches_exact(terms)
                  11
                elsif mark[:title].matches_score(terms) > 5
                  mark[:title].matches_score(terms)
                elsif mark[:url].matches_score(terms, start_word: false)
                  mark[:url].matches_score(terms, start_word: false)
                end

        { url: mark[:url], title: mark[:title], score: score }
      end

      ##
      ## Recursively parse bookmarks hash and score
      ## bookmarks
      ##
      ## @param      parent  [Hash, Array] The parent
      ##                     bookmark item
      ## @param      terms   [String] The search terms
      ##
      ## @return     [Array] array of scored bookmarks
      ##
      def get_safari_bookmarks(parent, terms)
        results = []

        if parent.is_a?(Array)
          parent.each do |c|
            if c.is_a?(Hash)
              if c.key?('Children')
                results.concat(get_safari_bookmarks(c['Children'], terms))
              elsif c.key?('URIDictionary')
                title = c['URIDictionary']['title']
                url = c['URLString']
                scored = score_bookmark({ url: url, title: title }, terms)

                results.push(scored) if scored[:score] > 7
              end
            end
          end
        elsif parent&.key?('Children')
          results.concat(get_safari_bookmarks(parent['Children'], terms))
        end

        results.sort_by { |h| [h[:score], h[:title].length * -1] }.reverse
      end
    end
  end
end

module SL
  # Browser history/bookmark search
  class HistorySearch
    class << self
      def settings
        {
          trigger: 'h(([scfabe])([hb])?)*',
          searches: [
            ['h', 'Browser History/Bookmark Search'],
            ['hsh', 'Safari History Search'],
            ['hsb', 'Safari Bookmark Search'],
            ['hshb', nil],
            ['hsbh', nil],
            ['hch', 'Chrome History Search'],
            ['hcb', 'Chrome Bookmark Search'],
            ['hchb', nil],
            ['hcbh', nil],
            ['hfh', 'Firefox History Search'],
            ['hfb', 'Firefox Bookmark Search'],
            ['hfhb', nil],
            ['hfbh', nil],
            ['hah', 'Arc History Search'],
            ['hab', 'Arc Bookmark Search'],
            ['hahb', nil],
            ['habh', nil],
            ['hbh', 'Brave History Search'],
            ['hbb', 'Brave Bookmark Search'],
            ['hbhb', nil],
            ['hbbh', nil],
            ['heh', 'Edge History Search'],
            ['heb', 'Edge Bookmark Search'],
            ['hehb', nil],
            ['hebh', nil]
          ]
        }
      end

      def search(search_type, search_terms, link_text)
        str = search_type.match(/^h(([scfabe])([hb])?)*$/)[1]

        types = []
        while str && str.length.positive?
          if str =~ /^s([hb]*)/
            t = Regexp.last_match(1)
            if t.length > 1 || t.empty?
              types.push('safari_history')
              types.push('safari_bookmarks')
            elsif t == 'h'
              types.push('safari_history')
            elsif t == 'b'
              types.push('safari_bookmarks')
            end
            str.sub!(/^s([hb]*)/, '')
          end

          if str =~ /^c([hb]*)/
            t = Regexp.last_match(1)
            if t.length > 1 || t.empty?
              types.push('chrome_bookmarks')
              types.push('chrome_history')
            elsif t == 'h'
              types.push('chrome_history')
            elsif t == 'b'
              types.push('chrome_bookmarks')
            end
            str.sub!(/^c([hb]*)/, '')
          end

          if str =~ /^f([hb]*)$/
            t = Regexp.last_match(1)
            if t.length > 1 || t.empty?
              types.push('firefox_bookmarks')
              types.push('firefox_history')
            elsif t == 'h'
              types.push('firefox_history')
            elsif t == 'b'
              types.push('firefox_bookmarks')
            end
            str.sub!(/^f([hb]*)/, '')
          end

          if str =~ /^e([hb]*)$/
            t = Regexp.last_match(1)
            if t.length > 1 || t.empty?
              types.push('edge_bookmarks')
              types.push('edge_history')
            elsif t == 'h'
              types.push('edge_history')
            elsif t == 'b'
              types.push('edge_bookmarks')
            end
            str.sub!(/^e([hb]*)/, '')
          end

          if str =~ /^b([hb]*)$/
            t = Regexp.last_match(1)
            if t.length > 1 || t.empty?
              types.push('brave_bookmarks')
              types.push('brave_history')
            elsif t == 'h'
              types.push('brave_history')
            elsif t == 'b'
              types.push('brave_bookmarks')
            end
            str.sub!(/^b([hb]*)/, '')
          end

          next unless str =~ /^a([hb]*)$/

          t = Regexp.last_match(1)
          if t.length > 1 || t.empty?
            types.push('arc_bookmarks')
            types.push('arc_history')
          elsif t == 'h'
            types.push('arc_history')
          elsif t == 'b'
            types.push('arc_bookmarks')
          end
          str.sub!(/^a([hb]*)/, '')
        end

        url, title = search_history(search_terms, types)
        link_text = title if link_text == '' || link_text == search_terms
        [url, title, link_text]
      end

      def search_history(term, types = [])
        if types.empty?
          return false unless SL.config['history_types']

          types = SL.config['history_types']
        end

        results = []

        if !types.empty?
          types.each do |type|
            url, title, date = send("search_#{type}", term)

            results << { 'url' => url, 'title' => title, 'date' => date } if url
          end

          if results.empty?
            false
          else
            out = results.sort_by! { |r| r['date'] }.last
            [out['url'], out['title']]
          end
        else
          false
        end
      end
    end

    SL::Searches.register 'history', :search, self
  end
end

module SL
  #
  # Hookmark String helpers
  #
  class ::String
    def split_hook
      elements = split(/\|\|/)
      {
        name: elements[0].nil_if_missing,
        url: elements[1].nil_if_missing,
        path: elements[2].nil_if_missing
      }
    end

    def split_hooks
      split(/\^\^/).map(&:split_hook)
    end
  end

  ##
  ## Hookmark Search
  ##
  class HookSearch
    class << self
      def settings
        {
          trigger: 'hook',
          searches: [
            ['hook', 'Hookmark Bookmark Search']
          ]
        }
      end

      # Main search method
      def search(_, search_terms, link_text)
        url, title = search_hook(search_terms)
        [url, title, link_text]
      end

      ##
      ## Run the AppleScript Hookmark query
      ##
      ## @param      query [String]  The query
      ##
      def run_query(query)
        `osascript <<'APPLESCRIPT'
          tell application "Hook"
            set _marks to every bookmark whose #{query}
            set _out to {}
            repeat with _hook in _marks
              set _out to _out & (name of _hook & "||" & address of _hook & "||" & path of _hook)
            end repeat
            set {astid, AppleScript's text item delimiters} to {AppleScript's text item delimiters, "^^"}
            set _output to _out as string
            set AppleScript's text item delimiters to astid
            return _output
          end tell
        APPLESCRIPT`.strip.split_hooks
      end

      # Search bookmark paths and addresses. Return array of bookmark hashes.
      def search_hook(search)
        types = %w[name path address]
        query = search.strip.split(' ').map { |s| types.map { |t| %(#{t} contains "#{s}") }.join(' or ') }
        query = query.map { |q| "(#{q})" }.join(' and ')
        path_matches = run_query(query)

        top_match = path_matches.uniq.first
        return false unless top_match

        [top_match[:url], top_match[:name]]
      end
    end

    SL::Searches.register 'hook', :search, self
  end
end

module SL
  class LastFMSearch
    class << self
      def settings
        {
          trigger: 'l(art|song)',
          searches: [
            ['lart', 'Last.fm Artist Search'],
            ['lsong', 'Last.fm Song Search']
          ]
        }
      end

      def search(search_type, search_terms, link_text)
        type = search_type =~ /art$/ ? 'artist' : 'track'

        url = URI.parse("http://ws.audioscrobbler.com/2.0/?method=#{type}.search&#{type}=#{search_terms.url_encode}&api_key=2f3407ec29601f97ca8a18ff580477de&format=json")
        res = Net::HTTP.get_response(url).body
        res = res.force_encoding('utf-8') if RUBY_VERSION.to_f > 1.9
        json = JSON.parse(res)
        return false unless json['results']

        begin
          case type
          when 'track'
            result = json['results']['trackmatches']['track'][0]
            url = result['url']
            title = "#{result['name']} by #{result['artist']}"
          when 'artist'
            result = json['results']['artistmatches']['artist'][0]
            url = result['url']
            title = result['name']
          end
          [url, title, link_text]
        rescue StandardError
          false
        end
      end
    end

    SL::Searches.register 'lastfm', :search, self
  end
end

module SL
  class PinboardSearch
    PINBOARD_CACHE = SL::Util.cache_file_for('pinboard')

    class << self
      def settings
        {
          trigger: 'pb',
          searches: [
            ['pb', 'Pinboard Bookmark Search']
          ]
        }
      end

      def pinboard_bookmarks
        bookmarks = `/usr/bin/curl -sSL "https://api.pinboard.in/v1/posts/all?auth_token=#{SL.config['pinboard_api_key']}&format=json"`
        bookmarks = bookmarks.force_encoding('utf-8')
        bookmarks.gsub!(/[^[:ascii:]]/) do |non_ascii|
          non_ascii.force_encoding('utf-8')
                   .encode('utf-16be')
                   .unpack('H*')
                   .gsub(/(....)/, '\u\1')
        end

        bookmarks.gsub!(/[\u{1F600}-\u{1F6FF}]/, '')

        bookmarks = JSON.parse(bookmarks)
        updated = Time.now
        { 'update_time' => updated, 'bookmarks' => bookmarks }
      end

      def save_pinboard_cache(cache)
        cachefile = PINBOARD_CACHE

        # file = File.new(cachefile,'w')
        # file = Zlib::GzipWriter.new(File.new(cachefile,'w'))
        begin
          File.open(cachefile, 'wb') { |f| f.write(Marshal.dump(cache)) }
        rescue IOError
          SL.add_error('Pinboard cache error', 'Failed to write stash to disk')
          return false
        end
        true
      end

      def load_pinboard_cache
        refresh_cache = false
        cachefile = PINBOARD_CACHE

        if File.exist?(cachefile)
          begin
            # file = IO.read(cachefile) # Zlib::GzipReader.open(cachefile)
            # cache = Marshal.load file
            cache = Marshal.load(File.binread(cachefile))
            # file.close
          rescue IOError # Zlib::GzipFile::Error
            SL.add_error('Error loading pinboard cache', "IOError reading #{cachefile}")
            cache = pinboard_bookmarks
            save_pinboard_cache(cache)
          rescue StandardError
            SL.add_error('Error loading pinboard cache', "StandardError reading #{cachefile}")
            cache = pinboard_bookmarks
            save_pinboard_cache(cache)
          end
          updated = JSON.parse(`/usr/bin/curl -sSL 'https://api.pinboard.in/v1/posts/update?auth_token=#{SL.config['pinboard_api_key']}&format=json'`)
          last_bookmark = Time.parse(updated['update_time'])
          if cache&.key?('update_time')
            last_update = cache['update_time']
            refresh_cache = true if last_update < last_bookmark
          else
            refresh_cache = true
          end
        else
          refresh_cache = true
        end

        if refresh_cache
          cache = pinboard_bookmarks
          save_pinboard_cache(cache)
        end

        cache
      end

      # Search pinboard bookmarks
      # Begin query with '' to force exact matching (including description text)
      # Regular matching searches for each word of query and scores the bookmarks
      # exact matches in title get highest score
      # exact matches in description get second highest score
      # other bookmarks are scored based on the number of words that match
      #
      # After sorting by score, bookmarks will be sorted by date and the most recent
      # will be returned
      #
      # Exact matching is case and punctuation insensitive
      def search(_, search_terms, link_text)
        unless SL.config['pinboard_api_key']
          SL.add_error('Missing Pinboard API token',
                       'Find your api key at https://pinboard.in/settings/password and add it
                        to your configuration (pinboard_api_key: YOURKEY)')
          return false
        end

        exact_match = false
        match_phrases = []

        # If search terms start with ''term, only search for exact string matches
        case search_terms
        when /^ *'/
          exact_match = true
          search_terms.gsub!(/(^ *'+|'+ *$)/, '')
        when /%22(.*?)%22/
          match_phrases = search_terms.scan(/%22(\S.*?\S)%22/)
          search_terms.gsub!(/%22(\S.*?\S)%22/, '')
        end

        cache = load_pinboard_cache
        # cache = pinboard_bookmarks
        bookmarks = cache['bookmarks']

        if exact_match
          bookmarks.each do |bm|
            text = [bm['description'], bm['extended'], bm['tags']].join(' ')

            return [bm['href'], bm['description']] if text.matches_exact(search_terms)
          end

          return false
        end

        unless match_phrases.empty?
          bookmarks.delete_if do |bm|
            matched = tru
            full_text = [bm['description'], bm['extended'], bm['tags']].join(' ')
            match_phrases.each do |phrase|
              matched = false unless full_text.matches_exact(phrase)
            end
            !matched
          end
        end

        matches = []
        bookmarks.each do |bm|
          title_tags = [bm['description'], bm['tags']].join(' ')
          full_text = [bm['description'], bm['extended'], bm['tags']].join(' ')

          score = if title_tags.matches_exact(search_terms)
                    14.0
                  elsif full_text.matches_exact(search_terms)
                    13.0
                  elsif full_text.matches_any(search_terms)
                    full_text.matches_score(search_terms)
                  else
                    0
                  end

          return [bm['href'], bm['description']] if score == 14

          next unless score.positive?

          matches.push({
                         score: score,
                         href: bm['href'],
                         title: bm['description'],
                         date: bm['time']
                       })
        end

        return false if matches.empty?

        top = matches.max_by { |bm| [bm[:score], bm[:date]] }

        return false unless top

        [top[:href], top[:title], link_text]
      end
    end

    SL::Searches.register 'pinboard', :search, self
  end
end

module SL
  class SocialSearch
    class << self
      def settings
        {
          trigger: '@[tfilm]',
          searches: [
            ['@t', 'Twitter Handle'],
            ['@f', 'Facebook Handle'],
            ['@i', 'Instagram Handle'],
            ['@l', 'LinkedIn Handle'],
            ['@m', 'Mastodon Handle']
          ]
        }
      end

      def search(search_type, search_terms, link_text = '')
        type = case search_type
               when /^@t/ # twitter-ify username
                 unless search_terms.strip =~ /^@?[0-9a-z_$]+$/i
                   return [false, "#{search_terms} is not a valid Twitter handle", link_text]

                 end

                 't'
               when /^@fb?/ # fb-ify username
                 unless search_terms.strip =~ /^@?[0-9a-z_]+$/i
                   return [false, "#{search_terms} is not a valid Facebook username", link_text]

                 end

                 'f'
               when /^@i/ # intagramify username
                 unless search_terms.strip =~ /^@?[0-9a-z_]+$/i
                   return [false, "#{search_terms} is not a valid Instagram username", link_text]

                 end

                 'i'
               when /^@l/ # linked-inify username
                 unless search_terms.strip =~ /^@?[0-9a-z_]+$/i
                   return [false, "#{search_terms} is not a valid LinkedIn username", link_text]

                 end

                 'l'
               when /^@m/ # mastodonify username
                 unless search_terms.strip =~ /^@?[0-9a-z_]+@[0-9a-z_.]+$/i
                   return [false, "#{search_terms} is not a valid Mastodon username", link_text]

                 end

                 'm'
               else
                 't'
               end

        url, title = social_handle(type, search_terms)
        link_text = title if link_text == ''
        [url, title, link_text]
      end

      def template_social(user, url, service)
        template = SL.config['social_template'].dup

        template.sub!(/%user%/, user)
        template.sub!(/%service%/, service)
        template.sub!(/%url%/, url.sub(%r{^https?://(www\.)?}, '').sub(%r{/$}, ''))

        template
      end

      def social_handle(type, term)
        handle = term.sub(/^@/, '').strip

        case type
        when /^t/i
          url = "https://twitter.com/#{handle}"
          title = template_social(handle, url, 'Twitter')
        when /^f/i
          url = "https://www.facebook.com/#{handle}"
          title = template_social(handle, url, 'Facebook')
        when /^l/i
          url = "https://www.linkedin.com/in/#{handle}/"
          title = template_social(handle, url, 'LinkedIn')
        when /^i/i
          url = "https://www.instagram.com/#{handle}/"
          title = template_social(handle, url, 'Instagram')
        when /^m/i
          parts = handle.split(/@/)
          return [false, term] unless parts.count == 2

          url = "https://#{parts[1]}/@#{parts[0]}"
          title = template_social(handle, url, 'Mastodon')
        else
          [false, term]
        end

        [url, title]
      end
    end

    SL::Searches.register 'social', :search, self
  end
end

module SL
  # Software Search
  class SoftwareSearch
    class << self
      def settings
        {
          trigger: 's',
          searches: [
            ['s', 'Software Search']
          ]
        }
      end

      def search(_, search_terms, link_text)
        excludes = %w[apple.com postmates.com download.cnet.com softpedia.com softonic.com macupdate.com]
        search_url = %(#{excludes.map { |x| "-site:#{x}" }.join(' ')} #{search_terms} app)

        url, title, link_text = SL.ddg(search_url, link_text)
        link_text = title if link_text == '' && !SL.titleize

        [url, title, link_text]
      end
    end

    SL::Searches.register 'software', :search, self
  end
end

module SL
  # Spelling Search
  class SpellSearch
    class << self
      def settings
        {
          trigger: 'sp(?:ell)?',
          searches: [
            %w[sp Spelling],
            ['spell', nil]
          ]
        }
      end

      def search(_, search_terms, link_text)
        title = SL.spell(search_terms)

        [title, title, link_text]
      end
    end

    SL::Searches.register 'spelling', :search, self
  end

  class << self
    def spell(phrase)
      aspell = if File.exist?('/usr/local/bin/aspell')
                 '/usr/local/bin/aspell'
               elsif File.exist?('/opt/homebrew/bin/aspell')
                 '/opt/homebrew/bin/aspell'
               else
                 `which aspell`.strip
               end

      if aspell.nil? || aspell.empty?
        SL.add_error('Missing aspell', 'Install aspell in to allow spelling corrections')
        return false
      end

      words = phrase.split(/\b/)
      output = ''
      words.each do |w|
        if w =~ /[A-Za-z]+/
          spell_res = `echo "#{w}" | #{aspell} --sug-mode=bad-spellers -C pipe | head -n 2 | tail -n 1`
          if spell_res.strip == "\*"
            output += w
          else
            spell_res.sub!(/.*?: /, '')
            results = spell_res.split(/, /).delete_if { |word| phrase =~ /^[a-z]/ && word =~ /[A-Z]/ }
            output += results[0]
          end
        else
          output += w
        end
      end
      output
    end
  end
end

module SL
  # Spotlight file search
  class SpotlightSearch
    class << self
      def settings
        {
          trigger: 'file',
          searches: [
            ['file', 'Spotlight Search']
          ]
        }
      end

      def search(_, search_terms, link_text)
        query = search_terms.gsub(/%22/, '"')
        res = `mdfind '#{query}' 2>/dev/null|head -n 1`
        return [false, query, link_text] if res.strip.empty?

        title = File.basename(res)
        link_text = title if link_text.strip.empty? || link_text == search_terms
        ["file://#{res.strip.gsub(/ /, '%20')}", title, link_text]
      end
    end

    SL::Searches.register 'spotlight', :search, self
  end
end

module SL
  # The Movie Database search
  class TMDBSearch
    class << self
      def settings
        {
          trigger: 'tmdb[amt]?',
          searches: [
            ['tmdb', 'TMDB Multi Search'],
            ['tmdba', 'TMDB Actor Search'],
            ['tmdbm', 'TMDB Movie Search'],
            ['tmdbt', 'TMDB TV Search']
          ]
        }
      end

      def search(search_type, terms, link_text)
        type = case search_type
               when /t$/
                 'tv'
               when /m$/
                 'movie'
               when /a$/
                 'person'
               else
                 'multi'
               end
        body = `/usr/bin/curl -sSL 'https://api.themoviedb.org/3/search/#{type}?query=#{terms.url_encode}&api_key=2bd76548656d92517f14d64766e87a02'`
        data = JSON.parse(body)
        if data.key?('results') && data['results'].count.positive?
          res = data['results'][0]
          type = res['media_type'] if type == 'multi'
          id = res['id']
          url = "https://www.themoviedb.org/#{type}/#{id}"
          title = res['name']
          title ||= res['title']
          title ||= terms
        else
          url, title, link_text = SL.ddg("site:imdb.com #{terms}", link_text)

          return false unless url
        end

        link_text = title if link_text == '' && !SL.titleize

        [url, title, link_text]
      end
    end

    SL::Searches.register 'tmdb', :search, self
  end
end

module SL
  class TwitterSearch
    class << self
      def settings
        {
          trigger: 'te',
          searches: [
            ['te', 'Twitter Embed']
          ]
        }
      end

      def search(search_type, search_terms, link_text)
        if SL::URL.url?(search_terms) && search_terms =~ %r{^https://twitter.com/}
          url, title = twitter_embed(search_terms)
        else
          SL.add_error('Invalid Tweet URL', "#{search_terms} is not a valid link to a tweet or timeline")
          url = false
          title = false
        end

        [url, title, link_text]
      end

      def twitter_embed(tweet)
        res = `curl -sSL 'https://publish.twitter.com/oembed?url=#{tweet.url_encode}'`.strip
        if res
          begin
            json = JSON.parse(res)
            url = 'embed'
            title = json['html']
          rescue StandardError
            SL.add_error('Tweet Error', 'Error retrieving tweet')
            url = false
            title = tweet
          end
        else
          return [false, 'Error retrieving tweet']
        end
        return [url, title]
      end
    end

    SL::Searches.register 'twitter', :search, self
  end
end

module SL
  class WikipediaSearch
    class << self
      def settings
        {
          trigger: 'wiki',
          searches: [
            ['wiki', 'Wikipedia Search']
          ]
        }
      end

      def search(_, search_terms, link_text)
        ## Hack to scrape wikipedia result
        body = `/usr/bin/curl -sSL 'https://en.wikipedia.org/wiki/Special:Search?search=#{search_terms.url_encode}&go=Go'`
        return false unless body

        body = body.force_encoding('utf-8') if RUBY_VERSION.to_f > 1.9

        begin
          title = body.match(/"wgTitle":"(.*?)"/)[1]
          url = body.match(/<link rel="canonical" href="(.*?)"/)[1]
        rescue StandardError
          return false
        end

        [url, title, link_text]
      end
    end

    SL::Searches.register 'wikipedia', :search, self
  end
end

module SL
  # YouTube Search/Linking
  class YouTubeSearch
    YOUTUBE_RX = %r{(?:youtu\.be/|youtube\.com/watch\?v=)?(?<id>[a-z0-9_\-]+)$}i.freeze

    class << self
      def settings
        {
          trigger: 'yte?',
          searches: [
            ['yt', 'YouTube Search'],
            ['yte', 'YouTube Embed']
          ]
        }
      end

      def search(search_type, search_terms, link_text)
        if SL::URL.url?(search_terms) && search_terms =~ YOUTUBE_RX
          url = search_terms
        elsif search_terms =~ /^[a-z0-9_\-]+$/i
          url = "https://youtube.com/watch?v=#{search_terms}"
        else
          url, title = SL.ddg("site:youtube.com #{search_terms}", link_text)
        end

        if search_type =~ /e$/ && url =~ YOUTUBE_RX
          m = Regexp.last_match
          id = m['id']
          url = 'embed'
          title = [
            %(<iframe width="560" height="315" src="https://www.youtube.com/embed/#{id}"),
            %(title="YouTube video player" frameborder="0"),
            %(allow="accelerometer; autoplay; clipboard-write; encrypted-media;),
            %(gyroscope; picture-in-picture; web-share"),
            %(allowfullscreen></iframe>)
          ].join(' ')
        end

        [url, title]
      end
    end

    SL::Searches.register 'youtube', :search, self
  end
end

module SL
  # Stack Overflow search
  class StackOverflowSearch
    class << self
      def settings
        {
          trigger: 'soa?',
          searches: [
            ['so', 'StackOverflow Search'],
            ['soa', 'StackOverflow Accepted Answer']
          ]
        }
      end

      def search(search_type, search_terms, link_text)
        url, title, link_text = SL.ddg("site:stackoverflow.com #{search_terms}", link_text)
        link_text = title if link_text == '' && !SL.titleize

        if search_type =~ /a$/
          body = `curl -SsL #{url}`.strip
          m = body.match(/id="(?<id>answer-\d+)"[^>]+accepted-answer/)
          url = "#{url}##{m['id']}" if m
        end

        [url, title, link_text]
      end
    end

    SL::Searches.register 'stackoverflow', :search, self
  end
end

module SL
  module URL
    class << self
      # Validates that a link exists and returns 200
      def valid_link?(uri_str, limit = 5)
        return false unless uri_str

        SL.notify('Validating', uri_str)
        return false if limit.zero?

        url = URI(uri_str)
        return true unless url.scheme

        url.path = '/' if url.path == ''
        # response = Net::HTTP.get_response(URI(uri_str))
        response = false

        Net::HTTP.start(url.host, url.port, use_ssl: url.scheme == 'https') do |http|
          response = http.request_head(url.path)
        end

        case response
        when Net::HTTPMethodNotAllowed, Net::HTTPServiceUnavailable
          unless /amazon\.com/ =~ url.host
            SL.add_error('link validation', "Validation blocked: #{uri_str} (#{e})")
          end
          SL.notify('Error validating', uri_str)
          true
        when Net::HTTPSuccess
          true
        when Net::HTTPRedirection
          location = response['location']
          valid_link?(location, limit - 1)
        else
          SL.notify('Error validating', uri_str)
          false
        end
      rescue StandardError => e
        SL.notify('Error validating', uri_str)
        SL.add_error('link validation', "Possibly invalid => #{uri_str} (#{e})")
        true
      end

      def url?(input)
        input =~ %r{^(#.*|https?://\S+|/\S+|\S+/|[^!]\S+\.\S+)(\s+".*?")?$}
      end

      def only_url?(input)
        input =~ %r{(?i)^((http|https)://)?([\w\-_]+(\.[\w\-_]+)+)([\w\-.,@?^=%&amp;:/~+#]*[\w\-@^=%&amp;/~+#])?$}
      end

      def ref_title_for_url(url)
        url = URI.parse(url) if url.is_a?(String)

        parts = url.hostname.split(/\./)
        domain = if parts.count > 1
                   parts.slice(-2, 1).join('')
                 else
                   parts.join('')
                 end

        path = url.path.split(%r{/}).last
        if path
          path.gsub!(/-/, ' ').gsub!(/\.\w{2-4}$/, '')
        else
          path = domain
        end

        path.length > domain.length ? path : domain
      end

      def url_to_link(url, type)
        input = url.dup

        if only_url?(input)
          input.sub!(%r{(?mi)^(?!https?://)(.*?)$}, 'https://\1')
          url = URI.parse(input.downcase)

          title = if type == :ref_title
                    ref_title_for_url(url)
                  else
                    get_title(url.to_s) || input.sub(%r{^https?://}, '')
                  end

          return [url.to_s, title] if url.hostname
        end
        false
      end

      def amazon_affiliatize(url, amazon_partner)
        return url if amazon_partner.nil? || amazon_partner.empty?

        unless url =~ %r{https?://(?<subdomain>.*?)amazon.com/(?:(?<title>.*?)/)?(?<type>[dg])p/(?<id>[^?]+)}
          return [url, '']
        end

        m = Regexp.last_match
        sd = m['subdomain']
        title = m['title']
        t = m['type']
        id = m['id']
        ["https://#{sd}amazon.com/#{t}p/#{id}/?ref=as_li_ss_tl&ie=UTF8&linkCode=sl1&tag=#{amazon_partner}", title]
      end

      def get_title(url)
        title = nil

        ## Gather proving too inexact
        # gather = false
        # ['/usr/local/bin', '/opt/homebrew/bin'].each do |root|
        #   if File.exist?(File.join(root, 'gather')) && File.executable?(File.join(root, 'gather'))
        #     gather = File.join(root, 'gather')
        #     break
        #   end
        # end

        # if gather
        #   cmd = %(#{gather} --title-only '#{url.strip}' --fallback-title 'Unknown')
        #   title = SL::Util.exec_with_timeout(cmd, 15)
        #   if title
        #     title = title.strip.gsub(/\n+/, ' ').gsub(/ +/, ' ')
        #     title.remove_seo!(url) if SL.config['remove_seo']
        #     return title.remove_protocol
        #   else
        #     SL.add_error('Error retrieving title', "Gather timed out on #{url}")
        #     SL.notify('Error retrieving title', 'Gather timed out')
        #   end
        # end

        begin
          source = `curl -SsL #{url}`.strip
          title = source && !source.empty? ? source.match(%r{<title>(.*)</title>}im) : nil

          title = title.nil? ? nil : title[1].strip

          if title.nil? || title =~ /^\s*$/
            SL.add_error('Title not found', "Warning: missing title for #{url.strip}")
            title = url.gsub(%r{(^https?://|/.*$)}, '').gsub(/-/, ' ').strip
          else
            title = title.gsub(/\n/, ' ').gsub(/\s+/, ' ').strip # .sub(/[^a-z]*$/i,'')
            title.remove_seo!(url) if SL.config['remove_seo']
          end
          title.gsub!(/\|/, '—')
          title.remove_seo!(url.strip) if SL.config['remove_seo']
          title.remove_protocol
        rescue StandardError
          SL.add_error('Error retrieving title', "Error determining title for #{url.strip}")
          warn "Error retrieving title for #{url.strip}"
          url.remove_protocol
        end
      end
    end
  end
end

# Main SearchLink class
module SL
  include URL

  class SearchLink
    include Plist

    attr_reader :originput, :output, :clipboard

    private

    #
    # Run a search
    #
    # @param[String]  search_type   The search type (abbreviation)
    # @param[String]  search_terms  The search terms
    # @param[String]  link_text     The link text
    # @param[Integer] search_count  The current search count
    #
    # @return [Array] [Url, link, text]
    #
    def do_search(search_type, search_terms, link_text = '', search_count = 0)
      if (search_count % 5).zero?
        SL.notify('Throttling for 5s')
        sleep 5
      end

      description = SL::Searches.description_for_search(search_type)

      SL.notify(description, search_terms)
      return [false, search_terms, link_text] if search_terms.empty?

      if SL::Searches.valid_search?(search_type)
        url, title, link_text = SL::Searches.do_search(search_type, search_terms, link_text)
      else
        case search_type
        when /^r$/ # simple replacement
          if SL.config['validate_links'] && !SL::URL.valid_link?(search_terms)
            return [false, "Link not valid: #{search_terms}", link_text]
          end

          title = SL::URL.get_title(search_terms) || search_terms

          link_text = title if link_text == ''
          return [search_terms, title, link_text]
        else
          if search_terms
            if search_type =~ /.+?\.\w{2,}$/
              url, title, link_text = SL.ddg(%(site:#{search_type} #{search_terms}), link_text)
            else
              url, title, link_text = SL.ddg(search_terms, link_text)
            end
          end
        end
      end

      if link_text == ''
        link_text = SL.titleize ? title : search_terms
      end

      if url && SL.config['validate_links'] && !SL::URL.valid_link?(url) && search_type !~ /^sp(ell)?/
        [false, "Not found: #{url}", link_text]
      elsif !url
        [false, "No results: #{url}", link_text]
      else
        [url, title, link_text]
      end
    end
  end
end

module SL
  class SearchLink
    def help_css
      <<~ENDCSS
        body{-webkit-font-smoothing:antialiased;font-family:"Avenir Next",Avenir,"Helvetica Neue",Helvetica,Arial,Verdana,sans-serif;
        margin:30px 0 0;padding:0;background:#fff;color:#303030;font-size:16px;line-height:1.5;text-align:center}h1{color:#000}
        h2{color:#111}p,td,div{color:#111;font-family:"Avenir Next",Avenir,"Helvetica Neue",Helvetica,Arial,Verdana,sans-serif;
        word-wrap:break-word}a{color:#de5456;text-decoration:none;-webkit-transition:color .2s ease-in-out;
        -moz-transition:color .2s ease-in-out;-o-transition:color .2s ease-in-out;-ms-transition:color .2s ease-in-out;
        transition:color .2s ease-in-out}a:hover{color:#3593d9}h1,h2,h3,h4,h5{margin:2.75rem 0 2rem;font-weight:500;line-height:1.15}
        h1{margin-top:0;font-size:2em}h2{font-size:1.7em}ul,ol,pre,table,blockquote{margin-top:2em;margin-bottom:2em}
        caption,col,colgroup,table,tbody,td,tfoot,th,thead,tr{border-spacing:0}table{border:1px solid rgba(0,0,0,0.25);
        border-collapse:collapse;display:table;empty-cells:hide;margin:-1px 0 1.3125em;padding:0;table-layout:fixed;margin:0 auto}
        caption{display:table-caption;font-weight:700}col{display:table-column}colgroup{display:table-column-group}
        tbody{display:table-row-group}tfoot{display:table-footer-group}thead{display:table-header-group}
        td,th{display:table-cell}tr{display:table-row}table th,table td{font-size:1.2em;line-height:1.3;padding:.5em 1em 0}
        table thead{background:rgba(0,0,0,0.15);border:1px solid rgba(0,0,0,0.15);border-bottom:1px solid rgba(0,0,0,0.2)}
        table tbody{background:rgba(0,0,0,0.05)}table tfoot{background:rgba(0,0,0,0.15);border:1px solid rgba(0,0,0,0.15);
        border-top:1px solid rgba(0,0,0,0.2)}p{font-size:1.1429em;line-height:1.72em;margin:1.3125em 0}dt,th{font-weight:700}
        table tr:nth-child(odd),table th:nth-child(odd),table td:nth-child(odd){background:rgba(255,255,255,0.06)}
        table tr:nth-child(even),table td:nth-child(even){background:rgba(200,200,200,0.25)}
        input[type=text] {padding: 5px;border-radius: 5px;border: solid 1px #ccc;font-size: 20px;}
      ENDCSS
    end

    def help_js
      <<~EOJS
        function filterTable() {
          let input, filter, table, tr, i, txtValue;
          input = document.getElementById("filter");
          filter = input.value.toUpperCase();
          table = document.getElementById("searches");
          table2 = document.getElementById("custom");

          tr = table.getElementsByTagName("tr");

          for (i = 0; i < tr.length; i++) {
              txtValue = tr[i].textContent || tr[i].innerText;
              if (txtValue.toUpperCase().indexOf(filter) > -1) {
                tr[i].style.display = "";
              } else {
                tr[i].style.display = "none";
              }
          }

          tr = table2.getElementsByTagName("tr");

          for (i = 0; i < tr.length; i++) {
              txtValue = tr[i].textContent || tr[i].innerText;
              if (txtValue.toUpperCase().indexOf(filter) > -1) {
                tr[i].style.display = "";
              } else {
                tr[i].style.display = "none";
              }
          }
        }
      EOJS
    end

    def help_text
      text = <<~EOHELP
        -- [Available searches] -------------------
        #{SL::Searches.available_searches}
      EOHELP

      if SL.config['custom_site_searches']
        text += "\n-- [Custom Searches] ----------------------\n"
        SL.config['custom_site_searches'].sort_by { |l, s| l }.each { |label, site| text += "!#{label}#{label.spacer} #{site}\n" }
      end
      text
    end

    def help_html
      out = ['<input type="text" id="filter" onkeyup="filterTable()" placeholder="Filter searches">']
      out << '<h2>Available Searches</h2>'
      out << SL::Searches.available_searches_html
      out << '<h2>Custom Searches</h2>'
      out << '<table id="custom">'
      out << '<thead><td>Shortcut</td><td>Search Type</td></thead>'
      out << '<tbody>'
      SL.config['custom_site_searches'].each { |label, site| out << "<tr><td><code>!#{label}</code></td><td>#{site}</td></tr>" }
      out << '</tbody>'
      out << '</table>'
      out.join("\n")
    end

    def help_dialog
      text = ["<html><head><style>#{help_css}</style><script>#{help_js}</script></head><body>"]
      text << '<h1>SearchLink Help</h1>'
      text << "<p>[#{SL.version_check}] [<a href='https://github.com/ttscoff/searchlink/wiki'>Wiki</a>]</p>"
      text << help_html
      text << '<p><a href="https://github.com/ttscoff/searchlink/wiki">Visit the wiki</a> for additional information</p>'
      text << '</body>'
      html_file = File.expand_path('~/.searchlink_searches.html')
      File.open(html_file, 'w') { |f| f.puts text.join("\n") }
      `open #{html_file}`
    end

    def help_cli
      $stdout.puts help_text
    end
  end
end

module SL
  class SearchLink
    def parse_arguments(string, opt={})
      input = string.dup
      return "" if input.nil?

      skip_flags = opt[:only_meta] || false
      no_restore = opt[:no_restore] || false
      restore_prev_config unless no_restore

      input.parse_flags! unless skip_flags

      options = %w[debug country_code inline prefix_random include_titles remove_seo validate_links]
      options.each do |o|
        if input =~ /^ *#{o}:\s+(\S+)$/
          val = Regexp.last_match(1).strip
          val = true if val =~ /true/i
          val = false if val =~ /false/i
          SL.config[o] = val
          $stderr.print "\r\033[0KGlobal config: #{o} = #{SL.config[o]}\n" unless SILENT
        end

        next if skip_flags

        while input =~ /^#{o}:\s+(.*?)$/ || input =~ /--(no-)?#{o}/
          next unless input =~ /--(no-)?#{o}/ && !skip_flags

          unless SL.prev_config.key? o
            SL.prev_config[o] = SL.config[o]
            bool = Regexp.last_match(1).nil? || Regexp.last_match(1) == '' ? true : false
            SL.config[o] = bool
            $stderr.print "\r\033[0KLine config: #{o} = #{SL.config[o]}\n" unless SILENT
          end
          input.sub!(/\s?--(no-)?#{o}/, '')
        end
      end
      SL.clipboard ? string : input
    end

    # Parse commands from the given input string
    #
    # @param      input  [String] the input string
    def parse_commands(input)
      # Handle commands like help or docs
      return unless input.strip =~ /^!?(h(elp)?|wiki|docs?|v(er(s(ion)?)?)?|up(date|grade))$/

      case input.strip
      when /^!?help$/i
        if SILENT
          help_dialog # %x{open http://brettterpstra.com/projects/searchlink/}
        else
          $stdout.puts SL.version_check.to_s
          $stdout.puts 'See https://github.com/ttscoff/searchlink/wiki for help'
        end
        print input
      when /^!?(wiki|docs)$/i
        warn 'Opening wiki in browser'
        `open https://github.com/ttscoff/searchlink/wiki`
      when /^!?v(er(s(ion)?)?)?$/
        print "[#{SL.version_check}]"
      when /^!?up(date|grade)$/
        SL.update_searchlink
        print SL.output.join('')
      end
      Process.exit 0
    end

    def parse(input)
      SL.output = []
      return false if input.empty?

      parse_arguments(input, { only_meta: true })
      SL.originput = input.dup

      parse_commands(input)

      SL.config['inline'] = true if input.scan(/\]\(/).length == 1 && input.split(/\n/).length == 1
      SL.errors = {}
      SL.report = []

      # Check for new version
      latest_version = SL.new_version?
      if latest_version
        SL.add_output("<!-- v#{latest_version} available, run SearchLink on the word 'update' to install. -->")
      end

      links = {}
      SL.footer = []
      counter_links = 0
      counter_errors = 0

      input.sub!(/\n?<!-- Report:.*?-->\n?/m, '')
      input.sub!(/\n?<!-- Errors:.*?-->\n?/m, '')

      input.scan(/\[(.*?)\]:\s+(.*?)\n/).each { |match| links[match[1].strip] = match[0] }

      prefix = if SL.config['prefix_random']
                 if input =~ /\[(\d{4}-)\d+\]: \S+/
                   Regexp.last_match(1)
                 else
                   format('%04d-', rand(9999))
                 end
               else
                 ''
               end

      highest_marker = 0
      input.scan(/^\s{,3}\[(?:#{prefix})?(\d+)\]: /).each do
        m = Regexp.last_match
        highest_marker = m[1].to_i if m[1].to_i > highest_marker
      end

      footnote_counter = 0
      input.scan(/^\s{,3}\[\^(?:#{prefix})?fn(\d+)\]: /).each do
        m = Regexp.last_match
        footnote_counter = m[1].to_i if m[1].to_i > footnote_counter
      end

      if input =~ /\[(.*?)\]\((.*?)\)/
        lines = input.split(/\n/)
        out = []

        total_links = input.scan(/\[(.*?)\]\((.*?)\)/).length
        in_code_block = false
        line_difference = 0
        lines.each_with_index do |line, num|
          SL.line_num = num - line_difference
          cursor_difference = 0
          # ignore links in code blocks
          if line =~ /^( {4,}|\t+)[^*+\-]/
            out.push(line)
            next
          end
          if line =~ /^[~`]{3,}/
            if in_code_block
              in_code_block = false
              out.push(line)
              next
            else
              in_code_block = true
            end
          end
          if in_code_block
            out.push(line)
            next
          end

          delete_line = false

          search_count = 0

          line.gsub!(/\[(.*?)\]\((.*?)\)/) do |match|
            this_match = Regexp.last_match
            SL.match_column = this_match.begin(0) - cursor_difference
            match_string = this_match.to_s
            SL.match_length = match_string.length
            match_before = this_match.pre_match

            invalid_search = false
            ref_title = false

            if match_before.scan(/(^|[^\\])`/).length.odd?
              SL.add_report("Match '#{match_string}' within an inline code block")
              invalid_search = true
            end

            counter_links += 1
            unless SILENT
              $stderr.print("\033[0K\rProcessed: #{counter_links} of #{total_links}, #{counter_errors} errors. ")
            end

            link_text = this_match[1] || ''
            link_info = parse_arguments(this_match[2].strip).strip || ''

            if link_text.strip == '' && link_info =~ /".*?"/
              link_info.gsub!(/"(.*?)"/) do
                m = Regexp.last_match(1)
                link_text = m if link_text == ''
                %("#")
              end
            end

            link_info.gsub!(/<(.*?)>/) do
              %(%22#{Regexp.last_match(1)}%22)
            end

            if link_info.strip =~ /:$/ && line.strip == match
              ref_title = true
              link_info.sub!(/\s*:\s*$/, '')
            end

            unless !link_text.empty? || !link_info.sub(/^[!\^]\S+/, '').strip.empty?
              SL.add_error('No input', match)
              counter_errors += 1
              invalid_search = true
            end

            if link_info =~ /^!(\S+)/
              search_type = Regexp.last_match(1)
              unless SL::Searches.valid_search?(search_type) || search_type =~ /^(\S+\.)+\S+$/
                SL.add_error("Invalid search#{SL::Searches.did_you_mean(search_type)}", match)
                invalid_search = true
              end
            end

            if invalid_search
              match
            elsif link_info =~ /^\^(.+)/
              m = Regexp.last_match
              if m[1].nil? || m[1] == ''
                match
              else
                note = m[1].strip
                footnote_counter += 1
                ref = if !link_text.empty? && link_text.scan(/\s/).empty?
                        link_text
                      else
                        format('%<p>sfn%<c>04d', p: prefix, c: footnote_counter)
                      end
                SL.add_footer "[^#{ref}]: #{note}"
                res = "[^#{ref}]"
                cursor_difference += (SL.match_length - res.length)
                SL.match_length = res.length
                SL.add_report("#{match_string} => Footnote #{ref}")
                res
              end
            # Handle [](URL) and [%](URL), filling in title
            elsif (link_text == '' || link_text == '%') && SL::URL.url?(link_info)
              url = link_info
              title = SL::URL.get_title(link_info)
              link_text = title

              if ref_title
                unless links.key? url
                  links[url] = link_text
                  SL.add_footer SL.make_link(:ref_title, link_text, url, title: title, force_title: false)
                end
                delete_line = true
              elsif SL.config['inline']
                res = SL.make_link(:inline, link_text, url, title: title, force_title: false)
                cursor_difference += SL.match_length - res.length
                SL.match_length = res.length
                SL.add_report("#{match_string} => #{url}")
                res
              else
                unless links.key? url
                  highest_marker += 1
                  links[url] = format('%<pre>s%<m>04d', pre: prefix, m: highest_marker)
                  SL.add_footer SL.make_link(:ref_title, links[url], url, title: title, force_title: false)
                end

                type = SL.config['inline'] ? :inline : :ref_link
                res = SL.make_link(type, link_text, links[url], title: false, force_title: false)
                cursor_difference += SL.match_length - res.length
                SL.match_length = res.length
                SL.add_report("#{match_string} => #{url}")
                res
              end
            elsif (link_text == '' && link_info == '') || SL::URL.url?(link_info)
              SL.add_error('Invalid search', match) unless SL::URL.url?(link_info)
              match
            else
              link_info = link_text if !link_text.empty? && link_info == ''

              search_type = ''
              search_terms = ''
              link_only = false
              SL.clipboard = false
              SL.titleize = SL.config['empty_uses_page_title']

              if link_info =~ /^(?:[!\^](\S+))\s*(.*)$/
                m = Regexp.last_match

                search_type = m[1].nil? ? 'g' : m[1]

                search_terms = m[2].gsub(/(^["']|["']$)/, '')
                search_terms.strip!

                # if the link text is just '%' replace with title regardless of config settings
                if link_text == '%' && search_terms && !search_terms.empty?
                  SL.titleize = true
                  link_text = ''
                end

                search_terms = link_text if search_terms == ''

                # if the input starts with a +, append it to the link text as the search terms
                search_terms = "#{link_text} #{search_terms.strip.sub(/^\+\s*/, '')}" if search_terms.strip =~ /^\+[^+]/

                # if the end of input contain "^", copy to clipboard instead of STDOUT
                SL.clipboard = true if search_terms =~ /(!!)?\^(!!)?$/

                # if the end of input contains "!!", only print the url
                link_only = true if search_terms =~ /!!\^?$/

                search_terms.sub!(/(!!)?\^?(!!)?$/,"")

              elsif link_info =~ /^!/
                search_word = link_info.match(/^!(\S+)/)

                if search_word && SL::Searches.valid_search?(search_word[1])
                  search_type = search_word[1] unless search_word.nil?
                  search_terms = link_text
                elsif search_word && search_word[1] =~ /^(\S+\.)+\S+$/
                  search_type = 'g'
                  search_terms = "site:#{search_word[1]} #{link_text}"
                else
                  SL.add_error("Invalid search#{SL::Searches.did_you_mean(search_word[1])}", match)
                  search_type = false
                  search_terms = false
                end
              elsif link_text && !link_text.empty? && (!link_info || link_info.empty?)
                search_type = 'g'
                search_terms = link_text
              elsif link_info && !link_info.empty?
                search_type = 'g'
                search_terms = link_info
              else
                SL.add_error('Invalid search', match)
                search_type = false
                search_terms = false
              end

              if search_type && !search_terms.empty?
                SL.config['custom_site_searches'].each do |k, v|
                  next unless search_type == k

                  link_text = search_terms if !SL.titleize && link_text == ''
                  v = parse_arguments(v, { no_restore: true })
                  if v =~ %r{^(/|http)}i
                    search_type = 'r'
                    tokens = v.scan(/\$term\d+[ds]?/).sort.uniq

                    if !tokens.empty?
                      highest_token = 0
                      tokens.each do |token|
                        if token =~ /(\d+)[ds]?$/ && Regexp.last_match(1).to_i > highest_token
                          highest_token = Regexp.last_match(1).to_i
                        end
                      end
                      terms_p = search_terms.split(/ +/)
                      if terms_p.length > highest_token
                        remainder = terms_p[highest_token - 1..-1].join(' ')
                        terms_p = terms_p[0..highest_token - 2]
                        terms_p.push(remainder)
                      end
                      tokens.each do |t|
                        next unless t =~ /(\d+)[ds]?$/

                        int = Regexp.last_match(1).to_i - 1
                        replacement = terms_p[int]
                        case t
                        when /d$/
                          replacement.downcase!
                          re_down = ''
                        when /s$/
                          replacement.slugify!
                          re_down = ''
                        else
                          re_down = '(?!d|s)'
                        end
                        v.gsub!(/#{Regexp.escape(t) + re_down}/, replacement.url_encode)
                      end
                      search_terms = v
                    else
                      search_terms = v.gsub(/\$term[ds]?/i) do |mtch|
                        search_terms.downcase! if mtch =~ /d$/i
                        search_terms.slugify! if mtch =~ /s$/i
                        search_terms.url_encode
                      end
                    end
                  else
                    search_type = 'g'
                    search_terms = "site:#{v} #{search_terms}"
                  end

                  break
                end
              end

              if (search_type && search_terms) || url
                # warn "Searching #{search_type} for #{search_terms}"
                if (!url)
                  search_count += 1

                  url, title, link_text = do_search(search_type, search_terms, link_text, search_count)

                end

                if url
                  title = SL::URL.get_title(url) if SL.titleize && title == ''

                  link_text = title if link_text == '' && title
                  force_title = search_type =~ /def/ ? true : false

                  if link_only || search_type =~ /sp(ell)?/ || url == 'embed'
                    url = title if url == 'embed'
                    cursor_difference += SL.match_length - url.length
                    SL.match_length = url.length
                    SL.add_report("#{match_string} => #{url}")
                    url
                  elsif ref_title
                    unless links.key? url
                      links[url] = link_text
                      SL.add_footer SL.make_link(:ref_title, link_text, url, title: title, force_title: force_title)
                    end
                    delete_line = true
                  elsif SL.config['inline']
                    res = SL.make_link(:inline, link_text, url, title: title, force_title: force_title)
                    cursor_difference += SL.match_length - res.length
                    SL.match_length = res.length
                    SL.add_report("#{match_string} => #{url}")
                    res
                  else
                    unless links.key? url
                      highest_marker += 1
                      links[url] = format('%<pre>s%<m>04d', pre: prefix, m: highest_marker)
                      SL.add_footer SL.make_link(:ref_title, links[url], url, title: title, force_title: force_title)
                    end

                    type = SL.config['inline'] ? :inline : :ref_link
                    res = SL.make_link(type, link_text, links[url], title: false, force_title: force_title)
                    cursor_difference += SL.match_length - res.length
                    SL.match_length = res.length
                    SL.add_report("#{match_string} => #{url}")
                    res
                  end
                else
                  SL.add_error('No results', "#{search_terms} (#{match_string})")
                  counter_errors += 1
                  match
                end
              else
                SL.add_error('Invalid search', match)
                counter_errors += 1
                match
              end
            end
          end
          line_difference += 1 if delete_line
          out.push(line) unless delete_line
          delete_line = false
        end
        warn "\n" unless SILENT

        input = out.delete_if { |l| l.strip =~ /^<!--DELETE-->$/ }.join("\n")

        if SL.config['inline']
          SL.add_output "#{input}\n"
          SL.add_output "\n#{SL.print_footer}" unless SL.footer.empty?
        elsif SL.footer.empty?
          SL.add_output input
        else
          last_line = input.strip.split(/\n/)[-1]
          case last_line
          when /^\[.*?\]: http/
            SL.add_output "#{input.rstrip}\n"
          when /^\[\^.*?\]: /
            SL.add_output input.rstrip
          else
            SL.add_output "#{input}\n\n"
          end
          SL.add_output "#{SL.print_footer}\n\n"
        end

        SL.line_num = nil
        SL.add_report("Processed: #{total_links} links, #{counter_errors} errors.")
        SL.print_report
        SL.print_errors
      else
        link_only = false
        SL.clipboard = false

        res = parse_arguments(input.strip!).strip
        input = res.nil? ? input.strip : res

        # if the end of input contain "^", copy to clipboard instead of STDOUT
        SL.clipboard = true if input =~ /\^[!~:\s]*$/

        # if the end of input contains "!!", only print the url
        link_only = true if input =~ /!![\^~:\s]*$/

        reference_link = input =~ /:([!\^~\s]*)$/

        # if end of input contains ~, pull url from clipboard
        if input =~ /~[:\^!\s]*$/
          input.sub!(/[:!\^\s~]*$/, '')
          clipboard = `__CF_USER_TEXT_ENCODING=$UID:0x8000100:0x8000100 pbpaste`.strip
          if SL::URL.url?(clipboard)
            type = reference_link ? :ref_title : :inline
            print SL.make_link(type, input.strip, clipboard)
          else
            print SL.originput
          end
          Process.exit
        end

        input.sub!(/[:!\^\s~]*$/, '')

        ## Maybe if input is just a URL, convert it to a link
        ## using hostname as text without doing search
        if SL::URL.only_url?(input.strip)
          type = reference_link ? :ref_title : :inline
          url, title = SL::URL.url_to_link(input.strip, type)
          print SL.make_link(type, title, url, title: false, force_title: false)
          Process.exit
        end

        # check for additional search terms in parenthesis
        additional_terms = ''
        if input =~ /\((.*?)\)/
          additional_terms = " #{Regexp.last_match(1).strip}"
          input.sub!(/\(.*?\)/, '')
        end

        # Maybe detect "search + addition terms" and remove additional terms from link text?
        # if input =~ /\+(.+?)$/
        #   additional_terms = "#{additional_terms} #{Regexp.last_match(1).strip}"
        #   input.sub!(/\+.*?$/, '').strip!
        # end

        link_text = false

        if input =~ /"(.*?)"/
          link_text = Regexp.last_match(1)
          input.gsub!(/"(.*?)"/, '\1')
        end

        # remove quotes from terms, just in case
        # input.sub!(/^(!\S+)?\s*(["'])(.*?)\2([\!\^]+)?$/, "\\1 \\3\\4")

        case input
        when /^!(\S+)\s+(.*)$/
          type = Regexp.last_match(1)
          link_info = Regexp.last_match(2).strip
          link_text ||= link_info
          terms = link_info + additional_terms
          terms.strip!

          if SL::Searches.valid_search?(type) || type =~ /^(\S+\.)+\S+$/
            if type && terms && !terms.empty?
              # Iterate through custom searches for a match, perform search if matched
              SL.config['custom_site_searches'].each do |k, v|
                next unless type == k

                link_text = terms if link_text == ''
                v = parse_arguments(v, { no_restore: true })
                if v =~ %r{^(/|http)}i
                  type = 'r'
                  tokens = v.scan(/\$term\d+[ds]?/).sort.uniq

                  if !tokens.empty?
                    highest_token = 0
                    tokens.each do |token|
                      t = Regexp.last_match(1)
                      highest_token = t.to_i if token =~ /(\d+)d?$/ && t.to_i > highest_token
                    end
                    terms_p = terms.split(/ +/)
                    if terms_p.length > highest_token
                      remainder = terms_p[highest_token - 1..].join(' ')
                      terms_p = terms_p[0..highest_token - 2]
                      terms_p.push(remainder)
                    end
                    tokens.each do |t|
                      next unless t =~ /(\d+)d?$/

                      int = Regexp.last_match(1).to_i - 1
                      replacement = terms_p[int]

                      re_down = case t
                                when /d$/
                                  replacement.downcase!
                                  ''
                                when /s$/
                                  replacement.slugify!
                                  ''
                                else
                                  '(?!d|s)'
                                end
                      v.gsub!(/#{Regexp.escape(t) + re_down}/, replacement.url_encode)
                    end
                    terms = v
                  else
                    terms = v.gsub(/\$term[ds]?/i) do |mtch|
                      terms.downcase! if mtch =~ /d$/i
                      terms.slugify! if mtch =~ /s$/i
                      terms.url_encode
                    end
                  end
                else
                  type = 'g'
                  terms = "site:#{v} #{terms}"
                end

                break
              end
            end

            # if contains TLD, use site-specific search
            if type =~ /^(\S+\.)+\S+$/
              terms = "site:#{type} #{terms}"
              type = 'g'
            end
            search_count ||= 0
            search_count += 1

            url, title, link_text = do_search(type, terms, link_text, search_count)
          else
            SL.add_error("Invalid search#{SL::Searches.did_you_mean(type)}", input)
            counter_errors += 1
          end
        # Social handle expansion
        when /^([tfilm])?@(\S+)\s*$/
          type = Regexp.last_match(1)
          unless type
            # If contains @ mid-handle, use Mastodon
            if Regexp.last_match(2) =~ /[a-z0-9_]@[a-z0-9_.]+/i
              type = 'm'
            else
              type = 't'
            end
          end
          link_text = input.sub(/^[tfilm]/, '')
          url, title = SL::SocialSearch.social_handle(type, link_text)
          link_text = title
        else
          link_text ||= input
          url, title, link_text = SL.ddg(input, link_text)
        end

        if url
          if type =~ /sp(ell)?/
            SL.add_output(url)
          elsif link_only
            SL.add_output(url)
          elsif url == 'embed'
            SL.add_output(title)
          else
            type = reference_link ? :ref_title : :inline

            SL.add_output SL.make_link(type, link_text, url, title: title, force_title: false)
            SL.print_errors
          end
        else
          SL.add_error('No results', title)
          SL.add_output SL.originput.chomp
          SL.print_errors
        end

        if SL.clipboard
          if SL.output == SL.originput
            warn 'No results found'
          else
            `echo #{Shellwords.escape(SL.output.join(''))}|tr -d "\n"|pbcopy`
            warn 'Results in clipboard'
          end
        end
      end
    end
  end
end

module SL
  class << self
    attr_writer :titleize, :clipboard, :output, :footer, :line_num,
                :match_column, :match_length, :originput, :errors, :report, :printout

    # Whether or not to add a title to the output
    def titleize
      @titleize ||= false
    end

    # Whether or not to copy results to clipbpard
    def clipboard
      @clipboard ||= false
    end

    # Whether or not to echo results to STDOUT as they're created
    def printout
      @printout ||= false
    end

    # Stores the generated output
    def output
      @output ||= []
    end

    # Stores the generated debug report
    def report
      @report ||= []
    end

    # Stores the footer with reference links and footnotes
    def footer
      @footer ||= []
    end

    # Tracks the line number of each link match for debug output
    def line_num
      @line_num ||= 0
    end

    # Tracks the column of each link match for debug output
    def match_column
      @match_column ||= 0
    end

    # Tracks the length of each link match for debug output
    def match_length
      @match_length ||= 0
    end

    # Stores the original input
    def originput
      @originput ||= ''
    end

    # Stores generated errors
    def errors
      @errors ||= {}
    end

    # Posts macOS notifications
    #
    # @param      str   The title of the notification
    # @param      sub   The text of the notification
    #
    def notify(str, sub)
      return unless SL.config['notifications']

      `osascript -e 'display notification "SearchLink" with title "#{str}" subtitle "#{sub}"'`
    end
  end
end

# The SL module provides methods for creating and manipulating links.
module SL
  class << self
    # Creates a link of the specified type with the given
    # text, url, and title.
    #
    # @param      type         [Symbol] The type of link to
    #                          create.
    # @param      text         [String] The text of the
    #                          link.
    # @param      url          [String] The URL of the link.
    # @param      title        [String] The title of the
    #                          link.
    # @param      force_title  [Boolean] Whether to force
    #                          the title to be included.
    #
    # @return     [String] The link.
    #
    def make_link(type, text, url, title: false, force_title: false)
      title = title.gsub(/\P{Print}|\p{Cf}/, '') if title
      text = title || SL::URL.get_title(url) if SL.titleize && (!text || text.strip.empty?)
      text = text ? text.strip : title
      title = title && (SL.config['include_titles'] || force_title) ? %( "#{title.clean}") : ''

      title.gsub!(/[ \t]+/, ' ')

      case type.to_sym
      when :ref_title
        %(\n[#{text}]: #{url}#{title})
      when :ref_link
        %([#{text}][#{url}])
      when :inline
        %([#{text}](#{url}#{title}))
      end
    end

    # Adds the given string to the output.
    #
    # @param      str   [String] The string to add.
    #
    # @return     [nil]
    #
    def add_output(str)
      print str if SL.printout && !SL.clipboard
      SL.output << str
    end

    # Adds the given string to the footer.
    #
    # @param      str   [String] The string to add.
    #
    # @return     [nil]
    #
    def add_footer(str)
      SL.footer ||= []
      SL.footer.push(str.strip)
    end

    # Prints the footer.
    #
    # @return     [String] The footer.
    #
    def print_footer
      unless SL.footer.empty?

        footnotes = []
        SL.footer.delete_if do |note|
          note.strip!
          case note
          when /^\[\^.+?\]/
            footnotes.push(note)
            true
          when /^\s*$/
            true
          else
            false
          end
        end

        output = SL.footer.sort.join("\n").strip
        output += "\n\n" if !output.empty? && !footnotes.empty?
        output += footnotes.join("\n\n") unless footnotes.empty?
        return output.gsub(/\n{3,}/, "\n\n")
      end

      ''
    end

    # Adds the given string to the report.
    #
    # @param      str   [String] The string to add.
    #
    # @return     [nil]
    #
    def add_report(str)
      return unless SL.config['report']

      unless SL.line_num.nil?
        position = "#{SL.line_num}:"
        position += SL.match_column.nil? ? '0:' : "#{SL.match_column}:"
        position += SL.match_length.nil? ? '0' : SL.match_length.to_s
      end
      SL.report.push("(#{position}): #{str}")
      warn "(#{position}): #{str}" unless SILENT
    end

    # Adds the given string to the errors.
    #
    # @param      type  [Symbol] The type of error.
    # @param      str   [String] The string to add.
    #
    # @return     [nil]
    #
    def add_error(type, str)
      return unless SL.config['debug']

      unless SL.line_num.nil?
        position = "#{SL.line_num}:"
        position += SL.match_column.nil? ? '0:' : "#{SL.match_column}:"
        position += SL.match_length.nil? ? '0' : SL.match_length.to_s
      end
      SL.errors[type] ||= []
      SL.errors[type].push("(#{position}): #{str}")
    end

    # Prints the report.
    #
    # @return     [String] The report.
    #
    def print_report
      return if (SL.config['inline'] && SL.originput.split(/\n/).length == 1) || SL.clipboard

      return if SL.report.empty?

      out = "\n<!-- Report:\n#{SL.report.join("\n")}\n-->\n"
      add_output out
    end

    # Prints the errors.
    #
    # @param      type  [String] The type of errors.
    #
    # @return     [String] The errors.
    #
    def print_errors(type = 'Errors')
      return if SL.errors.empty?

      out = ''
      inline = if SL.originput.split(/\n/).length > 1
                 false
               else
                 SL.config['inline'] || SL.originput.split(/\n/).length == 1
               end

      SL.errors.each do |k, v|
        next if v.empty?

        v.each_with_index do |err, i|
          out += "(#{k}) #{err}"
          out += if inline
                   i == v.length - 1 ? ' | ' : ', '
                 else
                   "\n"
                 end
        end
      end

      unless out == ''
        sep = inline ? ' ' : "\n"
        out.sub!(/\| /, '')
        out = "#{sep}<!-- #{type}:#{sep}#{out}-->#{sep}"
      end
      if SL.clipboard
        warn out
      else
        add_output out
      end
    end

    # Prints or copies the given text.
    #
    # @param      text  [String] The text to print or copy.
    #
    # @return     [nil]
    #
    def print_or_copy(text)
      # Process.exit unless text
      if SL.clipboard
        `echo #{Shellwords.escape(text)}|tr -d "\n"|pbcopy`
        print SL.originput
      else
        print text
      end
    end
  end
end

module Secrets; end

if RUBY_VERSION.to_f > 1.9
  Encoding.default_external = Encoding::UTF_8
  Encoding.default_internal = Encoding::UTF_8
end

sl = SL::SearchLink.new({ echo: false })

SL::Searches.load_custom

# # ignore
# SL::Searches.load_searches

overwrite = true
backup = SL.config['backup']

if !ARGV.empty?
  files = []
  ARGV.each do |arg|
    case arg
    when /^(--?)?h(elp)?$/
      print SL.version_check
      puts
      sl.help_cli
      $stdout.puts 'See https://github.com/ttscoff/searchlink/wiki for help'
      Process.exit
    when /^(--?)?v(er(s(ion)?)?)?$/
      print SL.version_check
      Process.exit
    when /^--?(stdout)$/
      overwrite = false
    when /^--?no[\-_]backup$/
      backup = false
    else
      files.push(arg)
    end
  end

  files.each do |file|
    if File.exist?(file) && `file -b "#{file}"|grep -c text`.to_i.positive?
      input = RUBY_VERSION.to_f > 1.9 ? IO.read(file).force_encoding('utf-8') : IO.read(file)

      backup_file = "#{file}.bak"
      backup_file = "#{file}.bak 1" if File.exist?(backup_file)
      backup_file.next! while File.exist?(backup_file)

      FileUtils.cp(file, backup_file) if backup && overwrite

      sl.parse(input)
      output = SL.output&.join('')

      next unless output

      if overwrite
        File.open(file, 'w') do |f|
          f.puts output
        end
      else
        puts output || input
      end
    else
      warn "Error reading #{file}"
    end
  end
else
  input = RUBY_VERSION.to_f > 1.9 ? $stdin.read.force_encoding('utf-8').encode : $stdin.read

  sl.parse(input)
  output = SL.output&.join('')

  if SL.clipboard
    print input
  else
    print output
  end
end
