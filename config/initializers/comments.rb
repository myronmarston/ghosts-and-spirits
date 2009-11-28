if Radiant::Config.table_exists?
  rc = Radiant::Config

  rc['comments.post_to_page?'] = true

  rc['comments.auto_approve'] = true
  rc['comments.filters_enabled'] = false

  rc['comments.notify_creator'] = false
  rc['comments.notify_updater'] = false
  rc['comments.notification'] = true
  rc['comments.notification_to'] = ENV['COMMENT_NOTIFICATION_ADDRESS']
  rc['comments.notification_site_name'] = 'ghostsandspirits.net'
  rc['comments.notification_from'] = "comment-notifier@ghostsandspirits.net"

  rc['comments.simple_spam_filter_required?'] = true
end