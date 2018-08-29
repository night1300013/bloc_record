module BlocRecord
  class Collection < Array
    def update_all(updates)
      ids = self.map(&:id)
      self.any? ? self.first.class.update(ids, updates) : false
    end

    def destroy_all
      ids = self.map(&:id)
      self.any? ? self.first.class.destroy(ids) : false
    end

    def take(num=1)
      self[0..num-1] if self.any?
    end

    def where(*args)
      ids = self.map(&:id)
      self.any? ? self.first.class.where(args.first, {ids: ids}) : false
    end

    def not(*args)
      ids = self.map(&:id)
      self.any? ? self.first.class.not(args.first, {ids: ids}) : false
    end
  end
end
