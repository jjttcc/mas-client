# Basic constants and queries specifying communication protocol
# components that are used by more than one application
module BasicCommunicationProtocol

  public

  ##### String constants

  MESSAGE_COMPONENT_SEPARATOR = "\t"
  # Character used to separate top-level message components

  MESSAGE_RECORD_SEPARATOR = "\n"
  # Character used to separate "records" or "lines" within
  # a message component

  MESSAGE_SUB_FIELD_SEPARATOR = ","
  # Character used to separate field sub-components

  MESSAGE_KEY_VALUE_SEPARATOR = ":"
  # Character used to separate a key/value pair

end
