# -*- encoding: utf-8 -*-

class Razor::Command::SetBootDevice < Razor::Command
  summary "Reset the Boot device for a node"
  description <<-EOT
Razor sets the boot device using the stored IPMI credentials.
ipmitool corresponding command is ipmitool -H 172.23.152.102 -U ADMIN -P ADMIN chassis bootdev <boot-device>

Valid options 
  ValidBootDevices = %w{none pxe disk safe diag cdrom bios floppy}

This is applied in the background, and will run as soon as available execution
slots are available for the task -- IPMI communication has some generous
internal rate limits to prevent it overwhelming the network or host server.

This background process is persistent: if you restart the Razor server before
the command is executed, it will remain in the queue and the operation will
take place after the server restarts.  There is no time limit on this at
this time.


If the IPMI request fails (that is: ipmitool reports it is unable to
communicate with the node) the request will be retried.  No detection of
actual results is included, though, so you may not know if the command is
delivered and fails to reboot the system.

  EOT

  example api: <<-EOT
Queue a node set boot device:

    {
      "name":          "node17",
      "boot_device": "pxe"
    }

  EOT

  example cli: <<-EOT
Queue a node to change boot device:

    razor set-boot-device --name node17 \\
        --boot-device pxe 

  EOT

  authz '%{name}'
  attr  'name', type: String, required: true, references: Razor::Data::Node,
                position: 0, help: _('The node on which to set boot device.')

  attr 'boot_device', type: String, required: true,
                        help: _('Boot device to use in the next boots.')



  def run(request, data)
    node = Razor::Data::Node[:name => data['name']]

     File.open("/tmp/bootdev", 'w') { |file| file.write(data['boot_device']) }

     node.publish 'bootdev!'

    { :result => _('set boot device request queued') }
  end
end
