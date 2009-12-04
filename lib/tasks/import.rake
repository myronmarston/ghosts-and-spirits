namespace :gs do
  namespace :import do

    def sql_string(table)
      file = File.join(Rails.root, 'db', 'original_site_data', "#{table}.sql")
      if File.exist?(file)
        File.open(file) { |f| f.read }
      else
        puts "File #{file} does not exist.  The file is needed for this rake task to run."
        exit
      end
    end

    def songs
      @songs ||= begin
        songs_by_id = {}
        song_sql = sql_string('songs')
        song_regex = /^\((\d+), '[^']+', '([^']+)'/ # http://rubular.com/regexes/12057

        song_sql.scan(song_regex) do |captures|
          songs_by_id[captures[0].to_i] = captures[1]
        end

        songs_by_id
      end
    end

    def ratings
      @ratings ||= begin
        ratings = []
        rating_sql = sql_string('ratings')
        rating_regex = /^\(\d+, (\d+), '([^']+)', '[^']+', (\d+), '([^']+)'/ # http://rubular.com/regexes/12058

        rating_sql.scan(rating_regex) do |captures|
          ratings << { :rating => captures[0].to_i, :created_at => DateTime.parse(captures[1]), :song_id => captures[2].to_i, :user_ip_address => captures[3] }
        end

        ratings
      end
    end

    def comments
      @comments ||= begin
        comments = []
        comment_sql = sql_string('comments')
        comment_regex = /^\(\d+, '(.+?)', '([^']+)', (\d+), '[^']+', '([\d\.]+)', '([^']+)', '([^']+)', '([^']*)', '([^']+)', '([^']+)'/ # http://rubular.com/regexes/12122

        comment_sql.scan(comment_regex) do |captures|
          comments << {
            :content => captures[0].gsub("''", "'").gsub(/<i>(.+?)<\/i>/, '_\1_').gsub("\\r", "\r").gsub("\\n", "\n"),
            :created_at => DateTime.parse(captures[1]),
            :song_id => captures[2].to_i,
            :author_ip => captures[3],
            :author => captures[4],
            :author_email => captures[5],
            :author_url => captures[6],
            :parent_page_slug => captures[7],
            :updated_at => DateTime.parse(captures[8])
          }
        end

        comments
      end
    end

    desc 'Import dynamic data from the original ghosts and spirits site'
    task :all => [:environment, :ratings, :comments]

    desc 'Import ratings data from the original ghosts and spirits site'
    task :ratings => :environment do
      $stdout.sync = true
      Rating.delete_all
      Page.update_all({ :average_rating => 0 })
      puts "Importing ratings: "
      ratings.each do |r|
        parent_page = Page.find_by_slug!('the-album')
        page = Page.find_by_parent_id_and_slug!(parent_page.id, songs[r[:song_id]])
        user_token = Digest::SHA1.hexdigest(r[:user_ip_address])
        page.add_rating(r[:rating], user_token)
        print '.'
      end

      puts
    end

    desc 'Import comments data from the original ghosts and spirits site'
    task :comments => :environment do
      Comment.class_eval do
        def auto_approve?
          true
        end

        def filter
          TextileFilter
        end
      end

      SimpleSpamFilter.class_eval do
        def valid?(comment)
          true
        end
      end

      $stdout.sync = true
      Comment.delete_all
      Page.update_all({ :comments_count => 0 })

      puts "Importing comments: "
      comments.each do |c|
        parent_page = Page.find_by_slug!(c.delete(:parent_page_slug))
        page = parent_page.children.find_by_slug!(songs[c.delete(:song_id)])
        comment = page.comments.build(c)
        comment.referrer = "http://ghostsandspirits.net#{page.url}"
        comment.author_ip = c[:author_ip]
        comment.save!
        Comment.update_all({ :created_at => c[:created_at], :updated_at => c[:updated_at] }, { :id => comment.id })
        print '.'
      end

      puts
    end
  end
end