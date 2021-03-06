module SecurityGroupHelper::TextualSummary
  #
  # Groups
  #

  def textual_group_properties
    %i(description type)
  end

  def textual_group_relationships
    %i(ems_cloud instances orchestration_stack)
  end

  def textual_group_firewall
    return nil if @record.firewall_rules.empty?
    @record.firewall_rules.collect do |rule|
      [
        rule.network_protocol,
        rule.host_protocol,
        rule.direction,
        rule.port,
        rule.end_port,
        (rule.source_ip_range || rule.source_security_group.try(:name) || "<None>")
      ]
    end.sort
  end

  def textual_group_tags
    %i(tags)
  end

  #
  # Items
  #

  def textual_description
    @record.description
  end

  def textual_type
    @record.type
  end

  def textual_ems_cloud
    textual_link(@record.ext_management_system)
  end

  def textual_instances
    label = ui_lookup(:tables => "vm_cloud")
    num   = @record.number_of(:vms)
    h     = {:label => label, :image => "vm", :value => num}
    if num > 0 && role_allows(:feature => "vm_show_list")
      h[:link]  = url_for(:action => 'show', :id => @security_group, :display => 'instances')
      h[:title] = _("Show all %{label}") % {:label => label}
    end
    h
  end

  def textual_orchestration_stack
    @record.orchestration_stack
  end
end
