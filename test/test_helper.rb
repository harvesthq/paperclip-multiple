require 'rubygems'
require 'bundler/setup'
require 'minitest/autorun'
require 'paperclip'
require 'paperclip-multiple'
require 'fog'
require 'active_support'
require 'active_record'

ActiveRecord::Base.establish_connection(
  adapter: "sqlite3", database: ":memory:"
)

ActiveRecord::Schema.suppress_messages do
  ActiveRecord::Schema.define version: 0 do
    create_table :users, force: true do |t|
      t.string  :avatar_file_name
      t.string  :avatar_content_type
    end
  end
end

Paperclip.options[:log] = false

Paperclip.interpolates(:compatible_path) do |attachment, _|
  if attachment.options[:storage] == :fog
    'uploads'
  else
    Dir.tmpdir
  end
end

Fog.mock!

FOG_CREDENTIALS = {
  aws_access_key_id: "whatever",
  aws_secret_access_key: "whatever",
  provider: "AWS"
}

FOG_DIRECTORY = 'bucket-name'

class User < ActiveRecord::Base
  include Paperclip::Glue

  cattr_accessor :s3_enabled, :display_from_s3

  has_attached_file :avatar, {
    storage: :multiple,
    multiple_storages: [:filesystem, :fog],

    fog_credentials: FOG_CREDENTIALS,
    fog_public:    true,
    fog_directory: FOG_DIRECTORY,

    styles: { thumbnail: '100x100>' },

    path: ":compatible_path/:class/:attachment/:id_partition/:style/:filename",
    url:  "/uploads/:class/:attachment/:id_partition/:style/:filename",

    multiple_if:              ->(_) { User.s3_enabled },
    display_from_destination: ->(_) { User.display_from_s3 }
  }

  validates_attachment_content_type :avatar, :content_type => /\Aimage/
end
