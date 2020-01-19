# Debugging facilities for SOCKETs
class SocketDebugger
  include Contracts::DSL

=begin
creation

  make_with_socket
=end

  private

  #####  Initialization

  # Initialize and start the timer.
  pre :s_exists do |s| s != nil end
  post :set do |result, s| self.target_socket == s end
  def initialize(s)
    @target_socket = s
  end

  public

  ##### Access

  # The target socket
  attr_reader :target_socket

  ##### Status report

  # Report on the state of: `s' if exists; otherwise,
  # `target_socket'.
  pre :s_exists_or_target_exists do |s| s != nil || target_socket != nil end
  def report(s)
      debug_socket = s
      if debug_socket.nil? then
        debug_socket = target_socket
      end
      result = "<<<BEGIN SOCKET REPORT>>>" + "\n" +
=begin
        "address_in_use: " +
         debug_socket.address_in_use.to_s + "\n" +
        "address_not_readable: " +
         debug_socket.address_not_readable.to_s + "\n" +
        "already_bound: " +
         debug_socket.already_bound.to_s + "\n" +
        "bad_socket_handle: " +
         debug_socket.bad_socket_handle.to_s + "\n" +
        "connect_in_progress: " +
         debug_socket.connect_in_progress.to_s + "\n" +
        "connection_refused: " +
         debug_socket.connection_refused.to_s + "\n" +
        "dtable_full: " +
         debug_socket.dtable_full.to_s + "\n" +
        "error: " +
         debug_socket.error.to_s + "\n" +
        "error_number: " +
         debug_socket.error_number.to_s + "\n" +
        "expired_socket: " +
         debug_socket.expired_socket.to_s + "\n" +
        "invalid_address: " +
         debug_socket.invalid_address.to_s + "\n" +
        "invalid_socket_handle: " +
         debug_socket.invalid_socket_handle.to_s + "\n" +
        "is_plain_text: " +
         debug_socket.is_plain_text.to_s + "\n" +
        "network: " +
         debug_socket.network.to_s + "\n" +
        "no_buffers: " +
         debug_socket.no_buffers.to_s + "\n" +
        "no_permission: " +
         debug_socket.no_permission.to_s + "\n" +
        "not_connected: " +
         debug_socket.not_connected.to_s + "\n" +
        "protected_address: " +
         debug_socket.protected_address.to_s + "\n" +
        "protocol_not_supported: " +
         debug_socket.protocol_not_supported.to_s + "\n" +
        "socket_family_not_supported: " +
         debug_socket.socket_family_not_supported.to_s + "\n" +
        "socket_in_use: " +
         debug_socket.socket_in_use.to_s + "\n" +
        "socket_ok: " +
         debug_socket.socket_ok.to_s + "\n" +
        "socket_would_block: " +
         debug_socket.socket_would_block.to_s + "\n" +
        "support_storable: " +
         debug_socket.support_storable.to_s + "\n" +
        "zero_option: " +
         debug_socket.zero_option.to_s + "\n" +
        "name: " +
         debug_socket.name.to_s + "\n" +
        "descriptor: " +
         debug_socket.descriptor.to_s + "\n" +
        "descriptor_available: " +
         debug_socket.descriptor_available.to_s + "\n" +
        "family: " +
         debug_socket.family.to_s + "\n" +
        "is_closed: " +
         debug_socket.closed?.to_s + "\n" +
        "peer_address: " +
         debug_socket.peer_address.to_s + "\n" +
        "protocol: " +
         debug_socket.protocol.to_s + "\n" +
        "type: " +
         debug_socket.type.to_s + "\n" +
        "c_msgdontroute: " +
         debug_socket.c_msgdontroute.to_s + "\n" +
        "c_oobmsg: " +
         debug_socket.c_oobmsg.to_s + "\n" +
        "c_peekmsg: " +
         debug_socket.c_peekmsg.to_s + "\n" +
        "exists: " +
         debug_socket.exists.to_s + "\n" +
        "extendible: " +
         debug_socket.extendible.to_s + "\n" +
        "is_executable: " +
         debug_socket.is_executable.to_s + "\n" +
        "is_open_read: " +
         debug_socket.is_open_read.to_s + "\n" +
        "is_open_write: " +
         debug_socket.is_open_write.to_s + "\n" +
        "is_readable: " +
         debug_socket.is_readable.to_s + "\n" +
        "is_writable: " +
         debug_socket.is_writable.to_s + "\n" +
        "readable: " +
         debug_socket.readable.to_s + "\n" +
        "debug_enabled: " +
         debug_socket.debug_enabled.to_s + "\n" +
        "is_blocking: " +
         debug_socket.is_blocking.to_s + "\n" +
        "is_group_id: " +
         debug_socket.is_group_id.to_s + "\n" +
        "is_process_id: " +
         debug_socket.is_process_id.to_s + "\n" +
        "is_socket_stream: " +
         debug_socket.is_socket_stream.to_s + "\n" +
        "receive_buf_size: " +
         debug_socket.receive_buf_size.to_s + "\n" +
        "route_enabled: " +
         debug_socket.route_enabled.to_s + "\n" +
        "send_buf_size: " +
         debug_socket.send_buf_size.to_s + "\n" +
=end
        "<<<END SOCKET REPORT>>>" + "\n"
=begin
      if debug_socket.is_group_id then
        result = result + "group_id: " +
         debug_socket.group_id.to_s + "\n"
      end
      if debug_socket.is_process_id then
        result = result + "process_id: " +
         debug_socket.process_id.to_s + "\n"
      end
      nw_stream_socket = debug_socket
      if nw_stream_socket != nil then
        result = "#{result}#{nss_report(nw_stream_socket)}"
      end
=end
#!!!!!:
result += " - stack:\n#{caller.join("\n")}"
      result
    end

  private

  ##### Implementation

  # Report on network stream socket `s'.
  pre :s_exists do |s| s != nil end
  def nss_report(s)
    result = "<<<BEGIN NETWORK_STREAM_SOCKET REPORT>>>" + "\n" +
# has_exception_state causes a delay - uncomment only if needed:
#        "has_exception_state: " + s.has_exception_state.to_s + "\n" +
      "port: " + s.port.to_s + "\n" +
#        "ready_for_reading: " + s.ready_for_reading.to_s + "\n" +
#        "ready_for_writing: " + s.ready_for_writing.to_s + "\n" +
      "reuse_address: " + s.reuse_address.to_s + "\n" +
      "timeout: " + s.timeout.to_s + "\n" +
      "is_linger_on: " + s.is_linger_on.to_s + "\n" +
      "is_out_of_band_inline: " + s.is_out_of_band_inline.to_s + "\n"+
      "linger_time: " + s.linger_time.to_s + "\n" +
      "maximum_seg_size: " + s.maximum_seg_size.to_s + "\n" +
      "<<<END NETWORK_STREAM_SOCKET REPORT>>>" + "\n"
    result
  end

end
