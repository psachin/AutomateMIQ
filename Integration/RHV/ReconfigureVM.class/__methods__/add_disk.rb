#
# This methods create additional disk and attaches to VM. User has
# choice to specify disk size and disk provisioning type using dialog
#
# This file is NOT a part of ManageIQ-content
# Copyright (C) 2017, Sachin Patil <psachin@redhat.com>
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# this program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

begin
  $evm.log(:info, "Attaching disk..")

  obj = $evm.object("process")
  vm = obj["vm"] || $evm.root["vm"]
  # vm.add_to_service()

  disk_name = "disk-99" #{vm.disks.count + 1}"
  disk_size = $evm.root['dialog_size']
  disk_thin_provisioned = $evm.root['dialog_thin_provisioned']
  $evm.log(:info, "Disk #{disk_name} with size #{disk_size} GB(Thin provisioned: #{disk_thin_provisioned})")

  vm.add_disk(disk_name, disk_size.to_i * 1024, {:thin_provisioned => disk_thin_provisioned})
  $evm.log(:info, "Disk added")
  $evm.create_notification(
    :level => "info",
    :message => "New disk successfully added to #{vm.name}")

  unless vm.name.nil?
    $evm.log("info", "Inspecting VM: <#{vm.inspect}>")

    ######################################
    #
    # Disk attached Email
    #
    ######################################

    # Get VM Owner Name and Email
    evm_owner_id = vm.attributes['evm_owner_id']
    owner = nil
    owner = $evm.vmdb('user', evm_owner_id) unless evm_owner_id.nil?
    $evm.log("info", "Inspecting VM Owner: #{owner.inspect}")

    # to_email_address from owner.email then from model if nil
    if owner
      to = owner.email
    else
      to = $evm.object['to_email_address']
    end

    # Get from_email_address from model unless specified below
    from = nil
    from ||= $evm.object['from_email_address']

    # Get signature from model unless specified below
    signature = nil
    signature ||= $evm.object['signature']

    # email subject
    subject = "New disk attached to VM: #{vm.name}"

    # Build email body
    body = "Hello, "
    body += "<br><br>Disk with #{disk_size} GB is attached to #{vm.name}."
    body += "<br><br>Thin provisioned: #{disk_thin_provisioned}."
    body += "<br><br>Thank you,"
    body += "<br> #{signature}"

    #
    # Send email
    #
    $evm.log("info", "Sending email to <#{to}> from <#{from}> subject: <#{subject}>")
    $evm.execute('send_email', to, from, subject, body)
    exit MIQ_OK
  end

rescue => err
  $evm.log(:error, "[(#{err.class})#{err}]\n#{err.backtrace.join("\n")}")
  $evm.create_notification(
    :level => "error",
    :message => "Disk failed to attach to #{vm.name}")

  exit MIQ_ERROR
end
