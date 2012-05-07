module MakeWatchable
  module Watchable
    extend ActiveSupport::Concern

    included do
      has_many :watchings, :class_name => "MakeWatchable::Watching", :as => :watchable
    end

    module ClassMethods
      def watchable?
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

    def watched_by?(watcher)
      watcher.watches?(self)
    end
  end
end
