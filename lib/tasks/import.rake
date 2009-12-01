namespace :gs do
  namespace :import do

    def sql_string(table)
      File.open(File.join(Rails.root, 'db', 'original_site_data', "#{table}.sql")) { |f| f.read }
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

    desc 'Import ratings data from the original ghosts and spirits site'
    task :ratings => :environment do
      Rating.delete_all
      Page.update_all({ :average_rating => 0 })
      puts "Importing ratings..."
      ratings.each do |r|
        parent_page = Page.find_by_slug!('the-album')
        page = Page.find_by_parent_id_and_slug!(parent_page.id, songs[r[:song_id]])
        user_token = Digest::SHA1.hexdigest(r[:user_ip_address])
        page.add_rating(r[:rating], user_token)
        print '.'
      end
    end
  end
end