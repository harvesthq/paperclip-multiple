module Paperclip
  module Storage
    ##
    # This is a Paperclip storage designed to migrate from one storage to another.
    module Multiple
      def self.extended(attachment)
        if attachment.options[:multiple_if].call(attachment.instance)
          attachment.instance_eval do
            origin_storage, destination_storage = attachment.options.delete(:multiple_storages)
            @origin      = Attachment.new(attachment.name, attachment.instance, attachment.options.merge(storage: origin_storage))
            @destination = Attachment.new(attachment.name, attachment.instance, attachment.options.merge(storage: destination_storage))

            # `after_flush_writes` closes files and unlinks them, but we have to read them twice to save them
            # on both multiple_storages, so we blank this one, and let the other attachment close the files.
            def @destination.after_flush_writes; end
          end
        else
          attachment.extend Filesystem
        end
      end

      def origin
        @origin
      end

      def destination
        @destination
      end

      def display_from_destination?
        @options[:display_from_destination].call(instance) && use_multiple?
      end

      ##
      # This defaults to the origin version.
      def exists?(style_name = default_style)
        origin.exists?
      end

      ##
      # Delegates to both filesystem and destination multiple_storages.
      def flush_writes
        sync(:@queued_for_write)

        @destination.flush_writes
        @origin.flush_writes

        @queued_for_write = {}
      end

      def queue_all_for_delete
        if use_multiple? && file?
          @origin.send      :queue_some_for_delete, *all_styles
          @destination.send :queue_some_for_delete, *all_styles
        end
        super
      end

      ##
      # Delegates to both multiple_storages.
      def flush_deletes
        @origin.flush_deletes
        begin
          @destination.flush_deletes
        rescue Excon::Errors::Error => e
          log("There was an unexpected error while deleting file from destination: #{e}")
        end
        @queued_for_delete = []
      end

      ##
      # This defaults to the origin version.
      def copy_to_local_file(style, local_dest_path)
        @origin.copy_to_local_file(style, local_dest_path)
      end

      def url(style_name = default_style, options = {})
        if display_from_destination?
          @destination.url(style_name, options)
        elsif use_multiple?
          @origin.url(style_name, options)
        else
          super
        end
      end

      def path(style_name = default_style)
        if display_from_destination?
          @destination.path(style_name)
        elsif use_multiple?
          @origin.path(style_name)
        else
          super
        end
      end

      ##
      # These two are needed for general fog working-around
      def public_url(style = default_style)
        if display_from_destination?
          @destination.public_url(style)
        elsif use_multiple?
          @origin.public_url(style)
        else
          super
        end
      end

      def expiring_url(time = 3600, style = default_style)
        if display_from_destination?
          @destination.expiring_url(time, style)
        elsif use_multiple?
          @origin.expiring_url(stime, tyle)
        else
          super
        end
      end

      private

      def all_styles
        [:original, *styles.keys]
      end

      def sync(ivar)
        @destination.instance_variable_set(ivar, instance_variable_get(ivar))
        @origin.instance_variable_set(ivar, instance_variable_get(ivar))
      end

      def use_multiple?
        @options[:multiple_if].call(instance)
      end
    end
  end
end
