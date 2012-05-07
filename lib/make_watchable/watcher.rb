module MakeWatchable
  module Watcher
    extend ActiveSupport::Concern

    included do
      has_many :watchings, :class_name => "MakeWatchable::Watching", :as => :watcher
    end

    module ClassMethods
      def watcher?
        true
      end

      # Method to find the ActiveRecord base class in case of STI
      # Required due to issue where Polymorphic models list their base class in the association
      # Thus we should also search for the baseclass when querying
      def sti_base_class
        return @sti_base_class unless @sti_base_class.nil?
        klass = self.class
        self.class.ancestors.each do |k|
          break if k == ActiveRecord::Base # we reached the bottom of this barrel
          klass = k if k.is_a? Class
        end
        @sti_base_class = klass
      end
    end

    # Watch a +watchable+.
    # Raises an +AlreadyWatchingError+ if the watcher already is watching the watchable.
    # Raises an +InvalidWatchableError+ if the watchable is not a valid watchable.
    def watch!(watchable)
      check_watchable(watchable)

      if watches?(watchable)
        raise Exceptions::AlreadyWatchingError.new
      end

      Watching.create(:watchable => watchable, :watcher => self)

      true
    end

    # Watch a +watchable+, but don't raise an error if the watcher is already watching the
    # watchable. Instead simply return false then and ignore the watch request.
    # Raises an +InvalidWatchableError+ if the watchable is not a valid watchable.
    def watch(watchable)
      begin
        watch!(watchable)
        success = true
      rescue Exceptions::AlreadyWatchingError
        success = false
      end
      success
    end

    # Unwatch a +watchable+.
    # Raises an +NotWatchingError if the watcher is not watching the watchable.
    # Raises an +InvalidWatchableError+ if the watchable is not a valid watchable.
    def unwatch!(watchable)
      check_watchable(watchable)

      watching = fetch_watching(watchable)

      raise Exceptions::NotWatchingError unless watching

      watching.destroy

      true
    end

    # Unwatch a +watchable+, but don't raise an error if the watcher is not watching
    # the watchable. Instead returns false.
    # Raises an +InvalidWatchableError+ if the watchable is not a valid watchable.
    def unwatch(watchable)
      begin
        unwatch!(watchable)
        success = true
      rescue Exceptions::NotWatchingError
        success = false
      end
      success
    end

    # Check if the watcher watches a watchable.
    def watches?(watchable)
      check_watchable(watchable)

      fetch_watching(watchable) ? true : false
    end

    private

    def fetch_watching(watchable)
      watchings.where({
        :watchable_type => watchable.class.sti_base_class.to_s,
        :watchable_id => watchable.id
      }).try(:first)
    end

    def check_watchable(watchable)
      raise Exceptions::InvalidWatchableError unless watchable.class.watchable?
    end
  end
end
