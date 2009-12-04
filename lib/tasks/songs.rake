namespace :gs do
  desc "Generate the playlist files for wimpy"
  task :generate_playlists => :environment do
    playlist_dir = File.join(Rails.root, "public", "wimpy", "playlists")

    Dir.glob(File.join(Rails.root, "public", "songs", "streaming", "*.mp3")) do |song_file_name|
      song = song_file_name.gsub('.mp3', '').split(/[^\w\-]/).last
      playlist_file_name = File.join(playlist_dir, "#{song}.xml")

      builder = Builder::XmlMarkup.new
      xml = builder.playlist do |playlist|
        playlist.item do |item|
          item.filename(File.join("/", "songs", "streaming", "#{song}.mp3"))
        end
      end

      puts "Writing playlist for #{song}..."

      File.open(playlist_file_name, "w") { |f| f.write xml }
    end    
  end

  desc "Copy the songs in to the local directory (sometimes necessary after a branch switch)"
  task :copy_songs => :environment do
    cp_r File.join(Rails.root, '..', 'ghosts-and-spirits-songs', '.'), File.join(Rails.root, "public", "songs")
  end
end