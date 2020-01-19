# Interface for cleanup notification before termination
module Terminable

  public

  ##### Utility

  # Perform any needed cleanup actions before program termination.
  def cleanup
    deferred
  end

end
