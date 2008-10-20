module SharedItem 

  def share!
    unless self.shared_access_id
      shared_access = SharedAccess.new
      shared_access.item= self
      logger.debug "New shared access for item_id #{shared_access.item_id}"
      shared_access.save!
      logger.debug "Saved new shared access for item_id #{shared_access.item_id}, new id #{shared_access.id}"
      self.update_attribute :shared_access_id, shared_access.id
      self.shared_access_id= shared_access.id
    end
    self.shared_access_id
  end
end
