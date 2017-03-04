#
# Description: Retrieve all <RHEL> templates
#
dialog_hash = {}
rhel_version ||= $evm.object['rhel_version']
$evm.log(:info, "RHEL_VERSION: #{rhel_version}")
templates = $evm.vmdb(:template_redhat).all.uniq {|t| t[:name]}
templates.each do |template|
  if /rhel/i === template.name
	dialog_hash[template[:guid]] = "#{template.name}, Disk size: #{template.disk_1_size / (1024 ** 3)} GB"
  end
end

if dialog_hash.blank?
  log(:info, "No Templates found")
  dialog_hash[''] = "<No Templates found>"
else
  dialog_hash[''] = '<choose a template>'
end

$evm.object["values"] = dialog_hash
