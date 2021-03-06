require 'holepicker/database'
require 'holepicker/utils'
require 'net/http'

module HolePicker
  class OnlineDatabase < Database
    URL='https://raw.github.com/jsuder/holepicker/master/lib/holepicker/data/data.json'

    def self.load
      puts "Fetching list of vulnerabilities..."

      load_from_json_file(http_get(URL)).tap do |db|
        db.check_compatibility
        db.report_new_vulnerabilities
      end
    rescue SystemExit
      raise
    rescue Exception => e
      puts "Can't download latest data file: #{e}"
      exit 1
    end

    def self.http_get(url)
      uri = URI(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = url.start_with?('https')

      response = http.get(uri.request_uri)
      response.body
    end

    def check_compatibility
      unless compatible?
        puts "You need to upgrade holepicker to version #{@min_version} or later."
        exit 1
      end
    end

    def report_new_vulnerabilities
      new_vulnerabilities = @vulnerabilities.select(&:recent?)
      count = new_vulnerabilities.length

      if count > 0
        puts "#{count} new #{Utils.pluralize(count, 'vulnerability')} found in the last " +
          "#{Vulnerability::NEW_VULNERABILITY_DAYS} days:"

        new_vulnerabilities.each do |v|
          puts "#{v.day} (#{v.gem_names.join(', ')}): #{v.url}"
        end

        puts
      end
    end
  end
end
