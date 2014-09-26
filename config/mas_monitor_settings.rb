class MasMonitorSettings

  attr_accessor :host, :main_port, :ports, :cmd_name_pattern, :server_start_cmd

  def initialize(cwd: Dir.pwd)
    @host = 'localhost'
    @ports = [5441, 5442, 5443, 5444]
    @main_port = @ports[0]
    @cmd_name_pattern = '^mas\b'
    @server_start_cmd = "cd #{cwd} >/dev/null && mas -b -w -f ,"
    @ports.each do |p| @server_start_cmd << " #{p}" end
  end

  def main_port=(p)
    if ! @ports.include?(p)
      @ports.unshift(p)
    end
    @main_port = p
  end

end
