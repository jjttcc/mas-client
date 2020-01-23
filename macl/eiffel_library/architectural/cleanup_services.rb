require 'general_utilities'

# Global services for cleanup registration and execution
module CleanupServices
  protected
  include Contracts::DSL, GeneralUtilities

  public

  ##### Utility

  # Add `v' to @@termination_registrants.
  pre  :not_registered do |v| ! @@termination_registrants.include?(v) end
  post :registered do |v| @@termination_registrants.include?(v) end
  def register_for_termination(v)
    if v != nil then
      @@termination_registrants << v
    end
  end

  # Remove (all occurrences of) `v' from @@termination_registrants.
  post :not_registered do ! @@termination_registrants.include?(v) end
  def unregister_for_termination(v)
    @@termination_registrants.reject! {|e| e == v}
  end

  # Send cleanup notification to all members of
  # `@@termination_registrants' in the order they were added
  # (with `register_for_termination').
  def termination_cleanup
    @@termination_registrants.each do |r|
      r.cleanup
    end
  end

  ##### Access

  # Registrants for termination cleanup notification
  @@termination_registrants = []

end
