# Global services for cleanup registration and execution
class CleanupServices <

  EXCEPTIONS
    export
      {NONE} all
      {ANY} deep_twin, is_deep_equal, standard_is_equal
    end

  GeneralUtilities
    export
      {NONE} all
    end

  public

  ##### Utility

  register_for_termination (v: TERMINABLE)
      # Add `v' to termination_registrants.
    require
      not_registered: not termination_registrants.has (v)
    do
      termination_registrants.extend (v)
    end

  unregister_for_termination (v: TERMINABLE)
      # Remove (all occurrences of) `v' from termination_registrants.
    do
      termination_registrants.prune_all (v)
    ensure
      not_registered: not termination_registrants.has (v)
    end

  termination_cleanup
      # Send cleanup notification to all members of
      # `termination_registrants' in the order they were added
      # (with `register_for_termination').
    do
      from
        termination_registrants.start
      until
        termination_registrants.exhausted
      loop
        termination_registrants.item.cleanup
        termination_registrants.forth
      end
    end

##### Access

  termination_registrants: LIST [TERMINABLE]
      # Registrants for termination cleanup notification
    once
      create {LINKED_LIST [TERMINABLE]} Result.make
    end

end
