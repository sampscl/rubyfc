# This will print the message every time any ship scans another
require 'pp'
$msg_hook = Proc.new do |object|
  gc = gc
  if(object["type"] == "scan_report" and object["reports"].length > 0)
    pp object["reports"]
  end  
end
