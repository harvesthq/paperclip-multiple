# paperclip-multiple

paperclip-multiple is a storage implementation for [Paperclip](https://github.com/thoughtbot/paperclip).
It aims to help migrating files from `filesystem` storage to [`fog`](http://fog.io) storage.

It provides the `multiple` storage which instantiates two `Attachments`, one using `filesystem` storage
and another using `fog` storage. From the moment the `multiple` storage is enabled, new files
will be stored on both locations while still displaying the files from the `filesystem`.

While paperclip-multiple helps you store files in two places, you will also want to sync
existing files. We used [`s3cmd`](http://s3tools.org/s3cmd) and
[`s3cmd sync`](http://s3tools.org/s3cmd-sync) to do this.

paperclip-multiple was prepared to migrate to S3. It was not prepared to:

* Migrate from S3 to filesystem.
* Migrate to use the `S3` backend instead of the `fog`.

Paperclip was not prepared to have multiple backends, so this little thing messes with
some of the internals of Paperclip.

## :warning: :warning: Warning :warning: :warning:

The nature of this software means that once we finished the migration, we aren't using it anymore.

It also messes with the internals of Paperclip, meaning it will possibly break in future
releases. We are not going to actively maintain this library, but we wanted to offer this code to
everyone that might find a use for it. We struggled to find any useful code in this regard, and
even an old version of what you see here, paperclip-multiple, would have been appreciated.

Feel free to ask questions or fork this code. For the reasons stated before, we might not be able
to provide with very good support. However, if there's something very obvious or broken and want
to contribute with a nice Pull Request, we'll do our best.

## Usage

Add paperclip-multiple to your Gemfile.

```ruby
gem 'paperclip-multiple', github: 'harvesthq/paperclip-multiple'
```

Make sure you have valid settings for both the filesystem and the fog storages. Let's suppose
you have information available in a constant like this:

```ruby
PAPERCLIP_SETTINGS = {
  fog_credentials: {
    aws_access_key_id: "whatever",
    aws_secret_access_key: "whatever",
    provider: "AWS"
  },
  fog_public:    true,
  fog_directory: "bucket-name"
}
```

Use it in your `has_attached_file` definition:

```ruby
class User
  has_attached_file :file, PAPERCLIP_SETTINGS.merge(
    storage: :multiple,
    path: ":compatible_rails_root/users/files/:user_id/:style.:extension",
    url:  "/uploads/users/files/:user_id/:style.:extension",
    multiple_if:     lambda { |user| user.company.s3_enabled?      },
    display_from_s3: lambda { |user| user.company.display_from_s3? }
  )
end
```

Three things might surprise you, let me explain them:

### What's that thing in your path?

You must not forget that Paperclip will be used for both fog and filesystem. If your `path`
option contained some absolute path, you'll have to tweak it to make it work with both storages.

This is what our `:compatible_rails_root` interpolation looks like:

```ruby
Paperclip.interpolates(:compatible_rails_root) do |attachment, _|
  if attachment.options[:storage] == :fog
    'uploads'
  else
    "#{rails_root(attachment, _)}/public/uploads"
  end
end
```

Be sure to test this in some staging environment. It's not trivial to get the slashes right!

### multiple_if

At Harvest we like to rollout things in slow, metered releases. The `multiple_if` option allows
you to define when an instance will indeed start using the multiple attachment. If this block
returns `false`, then it will work as if the `filesystem` backend was used.

### display_from_s3

This is the counterpart to the previous option. Multiple storage mainly delegates around
to the real `Attachment`. When you call `url` on your attachment, the multiple storage simply
calls the `Attachment` with the `filesystem` storage configured. If this block returns `true`,
it will call `url` on the `Attachment` with `fog` storage. A totally random example:

```ruby
user.company.display_from_s3? # => false
user.file.url # => '/uploads/users/files/1234/original.jpg'

user.company.display_from_s3? # => true
user.file.url # => 'https://whatever.s3.amazonaws.com/uploads/users/files/1234/original.jpg'
```

## Credits

[@mrsimo](https://github.com/mrsimo) built this to solve one of the multiple problems we face every day at
[Harvest](http://www.getharvest.com). We're [quite definitely hiring](http://www.getharvest.com/careers)!
