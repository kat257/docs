# frozen_string_literal: true

require 'csv'
require 'fileutils'
require 'set'

module CopyImages
  ##
  # Handles finding images, copying them, and *not* copying them if they have
  # already been copied.
  class Copier
    include Asciidoctor::Logging

    def initialize
      @copied = Set[]
    end

    def copy_image(block, uri)
      return unless @copied.add? uri      # Skip images we've copied before

      source = find_source block, uri
      return unless source                # Skip images we can't find

      logger.info message_with_context "copying #{source}", :source_location => block.source_location
      copy_image_proc = block.document.attr 'copy_image'
      if copy_image_proc
        # Delegate to a proc for copying if one is defined. Used for testing.
        copy_image_proc.call(uri, source)
      else
        destination = ::File.join block.document.options[:to_dir], uri
        destination_dir = ::File.dirname destination
        FileUtils.mkdir_p destination_dir
        FileUtils.cp source, destination
      end
    end

    ##
    # Does a breadth first search starting at the base_dir of the document and
    # any referenced resources. This isn't super efficient but it is how a2x works
    # and we strive for compatibility.
    #
    def find_source(block, uri)
      to_check = [block.document.base_dir]
      checked = []

      resources = block.document.attr 'resources'
      if resources && !resources.empty?
        begin
          to_check += CSV.parse_line(resources)
        rescue CSV::MalformedCSVError => error
          logger.error message_with_context "Error loading [resources]: #{error}",
              :source_location => block.source_location
        end
      end

      while (dir = to_check.shift)
        checked << block.normalize_system_path(uri, dir)
        return checked.last if File.readable? checked.last
        next unless Dir.exist?(dir)

        Dir.new(dir).each do |f|
          next if ['.', '..'].include? f

          f = File.join(dir, f)
          to_check << f if File.directory?(f)
        end
      end

      # We'll skip images we can't find but we should log something about it so
      # we can fix them.
      checked.sort! do |lhs, rhs|
        by_depth = lhs.scan(%r{/}).count <=> rhs.scan(%r{/}).count
        if by_depth != 0
          by_depth
        else
          lhs <=> rhs
        end
      end
      logger.warn message_with_context "can't read image at any of #{checked}", :source_location => block.source_location
      nil
    end
  end
end
