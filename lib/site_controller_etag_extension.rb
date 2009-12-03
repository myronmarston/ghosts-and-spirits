module SiteControllerEtagExtension
  def self.included(base)
    base.alias_method_chain :set_cache_control, :etag
  end

  private

  def set_cache_control_with_etag
    if (request.head? || request.get?) && @page.cache? && @page.enable_comments?
      expires_in nil, :private => true, "no-cache" => true

      # Note: when a comment is added, :comment_count and :lock_version are updated.  :updated_at is not.
      headers['ETag'] = Digest::MD5.hexdigest("#{@page.updated_at.to_s} : #{@page.lock_version.to_s}")
    else
      set_cache_control_without_etag
    end
  end
end