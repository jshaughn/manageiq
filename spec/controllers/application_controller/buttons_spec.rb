describe ApplicationController do
  context "#custom_buttons" do
    let(:resource_action) { FactoryGirl.create(:resource_action, :dialog_id => 1) }
    let(:button)          { FactoryGirl.create(:custom_button, :name => "My Button", :applies_to_class => "Vm", :resource_action => resource_action) }
    let(:template)        { FactoryGirl.create(:template_vmware, :name => "My Template") }
    let(:vm)              { FactoryGirl.create(:vm_vmware, :name => "My VM") }

    context "with a resource_action dialog" do
      it "Vm button" do
        controller.instance_variable_set(:@_params, :id => vm.id, :button_id => button.id)
        expect(controller).to receive(:dialog_initialize) do |action, options|
          expect(action).to eq(resource_action)
          expect(options[:target_id]).to eq(vm.id)
          expect(options[:target_kls]).to eq(vm.class.name)
        end

        controller.send(:custom_buttons)
        expect(assigns(:right_cell_text)).to include(vm.name)
      end

      it "MiqTemplate button" do
        # TODO: change to update_attribute once CustomButton is fixed:  https://github.com/ManageIQ/cfme/issues/335
        button.update_attributes(:applies_to_class => "MiqTemplate")
        controller.instance_variable_set(:@_params, :id => template.id, :button_id => button.id)

        expect(controller).to receive(:dialog_initialize) do |action, options|
          expect(action).to eq(resource_action)
          expect(options[:target_id]).to eq(template.id)
          expect(options[:target_kls]).to eq(template.class.name)
        end

        controller.send(:custom_buttons)
        expect(assigns(:right_cell_text)).to include(template.name)
      end
    end

    context "without a resource_action dialog" do
      before :each do
        resource_action.update_attribute(:dialog_id, nil)
        expect(controller).to receive(:render)
      end

      it "Vm button" do
        controller.instance_variable_set(:@_params, :id => vm.id, :button_id => button.id)
        expect_any_instance_of(CustomButton).to receive(:invoke).with(vm)

        controller.send(:custom_buttons)
        expect(assigns(:right_cell_text)).to include(vm.name)
      end

      it "MiqTemplate" do
        button.update_attributes(:applies_to_class => "MiqTemplate")
        controller.instance_variable_set(:@_params, :id => template.id, :button_id => button.id)
        expect_any_instance_of(CustomButton).to receive(:invoke).with(template)

        controller.send(:custom_buttons)
        expect(assigns(:right_cell_text)).to include(template.name)
      end
    end

    context "#button_create_update" do
      it "no need to set @record when add/cancel form buttons are pressed" do
        custom_button = FactoryGirl.create(:custom_button, :applies_to_class => "Host")
        controller.instance_variable_set(:@_params, :button => "cancel", :id => custom_button.id)
        edit = {
          :new           => {},
          :current       => {},
          :custom_button => custom_button
        }
        controller.instance_variable_set(:@edit, edit)
        session[:edit] = edit
        controller.instance_variable_set(:@sb,
                                         :trees       => {
                                           :ab_tree => {:active_node => "-ub-Host"}
                                         },
                                         :active_tree => :ab_tree
                                        )
        allow(controller).to receive(:ab_get_node_info)
        allow(controller).to receive(:replace_right_cell)
        controller.send(:button_create_update, "add")
        expect(@record).to be_nil
      end
    end
  end

  context "#button_set_form_vars" do
    it "check button_set_form_vars sets correct applies_to_class when editing a button" do
      # button_set_form_vars expects that the simulation screen will be built,
      #   which, in turn, needs *something* to come back from automate
      allow(MiqAeClass).to receive_messages(:find_distinct_instances_across_domains => [double(:name => "foo")])

      custom_button = FactoryGirl.create(:custom_button, :applies_to_class => "Vm")
      custom_button.uri_path, custom_button.uri_attributes, custom_button.uri_message = CustomButton.parse_uri("/test/")
      custom_button.uri_attributes["request"] = "req"
      custom_button.save
      controller.instance_variable_set(:@_params, :id => custom_button.id)
      controller.instance_variable_set(:@custom_button, custom_button)
      controller.instance_variable_set(:@sb,
                                       :trees       => {
                                         :ab_tree => {:active_node => "-ub-Vm_cb-10r51"}
                                       },
                                       :active_tree => :ab_tree
                                      )
      controller.send(:button_set_form_vars)
      expect(assigns(:edit)[:new][:target_class]).to eq(ui_lookup(:model => "Vm"))

      controller.instance_variable_set(:@sb,
                                       :trees       => {
                                         :ab_tree => {:active_node => "xx-ab_Vm_cbg-10r96_cb-10r7"}
                                       },
                                       :active_tree => :ab_tree
                                      )
      controller.send(:button_set_form_vars)
      expect(assigns(:edit)[:new][:target_class]).to eq(ui_lookup(:model => "Vm"))
    end
  end
end
