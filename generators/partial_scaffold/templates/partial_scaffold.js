PartialResource = {};
PartialResource.Base = Class.create();
PartialResource.Base.prototype = {
    initialize: function(owner, controller, attributes){
        this.owner = owner;
        this.controller = controller;
        Object.extend(this, attributes);
    },

    activate: function(){
        this.content_pane = $(this.content_pane); 
        this.initialize_contents();
    },

    // must implement "initialize_contents: function(){}"

    initialize_actions: function(pane){
        var regexp = /^click_/;
        for(var prop in this){
            if (!prop.match(regexp))
                continue;
            var handler = this[prop];
            if (handler.constructor != Function)
                continue;
            var url_prop = prop.gsub("click_link_", "url_");
            var element_prop = prop.gsub("click_", "element_of_");
            this[url_prop] = null;
            this[element_prop] = null;
            var link_prop = prop.gsub("click_link_", "link_");
            var elements = pane.getElementsByClassName(link_prop);
            if (elements.length < 1)
                continue;
            var element = elements[0];
            if (element && !this[element_prop]) {
                this[element_prop] = element;
                if (element.tagName == "A" && element.href && (element.href != "javascript:void(0)")){
                    this[url_prop] = element.href;
                    element.href = "javascript:void(0)";
                }
                Event.observe(element, "click", handler.bindAsEventListener(this));
            }
        }
    },
    
    root_controller: function(){
        return this.owner ? this.owner.root_controller() : this;
    },
    
    ajax_delete: function(url, element_id){
        var delete_parameters = this.root_controller().ajax_delete_parameters;
        if (delete_parameters == null){
            throw new Error("'ajax_delete_parameters' option is not specified");
        }
        new Ajax.Request(url,
            { method: 'post',
              parameters: '_method=delete&redirection=render_null&' + delete_parameters,
              onComplete: function(){Element.remove($(element_id));} 
            });
    }
}

PartialResource.New = Class.create();
PartialResource.New.prototype = {
    initialize: function(){
    },
    
    has_one: function(controller, attributes){
        return new PartialResource.NewHasOne(this, controller, attributes);
    },
    
    has_many: function(controller, attributes){
        return new PartialResource.NewHasMany(this, controller, attributes);
    }
}
PartialResource.New.FieldCustomizeMethods = {
    modify_field_names: function(pane){
        this.modify_field_names_for(pane.getElementsByTagName("INPUT"));
        this.modify_field_names_for(pane.getElementsByTagName("select"));
        this.modify_field_names_for(pane.getElementsByTagName("textarea"));
    },

    modify_field_names_for: function(fields){
        if (!this.field_names_to)
            return;
        for(var i=0; i< fields.length; i++){
            var field = fields[i];
            for(var key in this.field_names_to){
                if (field.name.include(key)){
                    field.name = field.name.sub(key, this.field_names_to[key]);
                    break;
                }
            }
        }
    }
};


PartialResource.NewHasOne = Class.create();
Object.extend(PartialResource.NewHasOne.prototype, PartialResource.Base.prototype);
Object.extend(PartialResource.NewHasOne.prototype, PartialResource.New.FieldCustomizeMethods);
Object.extend(PartialResource.NewHasOne.prototype, {
    initialize_contents: function(){
        this.initialize_actions(this.content_pane);
        this.modify_field_names(this.content_pane);
    }
});

PartialResource.HasManyMethods = {
    initialize_contents: function(){
        this.action_pane = $(this.action_pane);
        if (this.action_pane) {
            this.initialize_actions(this.action_pane);
        } else {
            // throw new Error("has_many require action_pane")
        }
        this.initialize_actions(this.content_pane);
        var panes = this.content_pane.getElementsByClassName(this.record_pane_class());
        for(var i=0; i< panes.length; i++){
            this.add_new_item(panes[i]).activate();
        }
    },

    add_new_item: function(pane){
        this.items = this.items || [];
        var item = this.new_item(pane);
        this.items.push(item);
        return item;
    },

    record_pane_class: function(){
        return this.pane_class_name || (this.controller + "_content");
    },

    find_item_for: function(pane){
        var pane = $(pane);
        if (this.items == null)
            return null;
        for(var i = 0; i < this.items.length; i++){
            var item = this.items[i];
            if (item.content_pane == pane)
                return item;
        }
        return null;
    }
}


PartialResource.NewHasMany = Class.create();
Object.extend(PartialResource.NewHasMany.prototype, PartialResource.Base.prototype);
Object.extend(PartialResource.NewHasMany.prototype, PartialResource.HasManyMethods);
Object.extend(PartialResource.NewHasMany.prototype, {
    new_item: function(pane){
        return new PartialResource.NewHasManyItem(this, this.controller, {
            content_pane: pane,
            field_names_to: this.field_names_to
        });
    },

    click_link_to_add: function(event){
        var new_pane = document.createElement("DIV");
        new_pane.id = "new_pane" + (new Date).getTime();
        Element.addClassName(new_pane, this.record_pane_class());
        this.content_pane.appendChild(new_pane);
        var item = this.add_new_item(new_pane);
        new Ajax.Updater(new_pane, 
                         "/" + this.controller + "/new", 
                         { method: 'get', evalScripts: true, 
                           onComplete: item.activate.bind(item)});
    }
});

PartialResource.NewHasManyItem = Class.create();
Object.extend(PartialResource.NewHasManyItem.prototype, PartialResource.Base.prototype);
Object.extend(PartialResource.NewHasManyItem.prototype, PartialResource.New.FieldCustomizeMethods);
Object.extend(PartialResource.NewHasManyItem.prototype, {
    initialize_contents: function(){
        this.initialize_actions(this.content_pane);
        this.modify_field_names(this.content_pane);
    },

    click_link_to_destroy: function(event){
        this.content_pane.remove();
    }
});



PartialResource.Editable = Class.create();
PartialResource.Editable.SubmittableMethods = {
    initialize_contents: function(){
        this.update_contents();
    },

    update_contents: function(){
        this.initialize_actions(this.content_pane);
        var form = this.get_form();
        if (form) {
            // Ajax can't send "multipart/form-data" .
            // So you can use responds_to_parent plugin if you need to upload files with ajax.
            // http://code.google.com/p/responds-to-parent/source/checkout
            // So PartialResource doesn't handle submit event if form's target is set 
            // because the plugin uses form "target" attribute.
            if (form.target) {
                // Add hidden field in form for sending item_pane_id parameter even if not using Ajax. 
                if (this.content_pane) {
                    var content_pane_hidden = document.createElement("INPUT");
                    content_pane_hidden.type = "hidden";
                    content_pane_hidden.name = "item_pane_id";
                    content_pane_hidden.value = this.content_pane.id;
                    form.appendChild(content_pane_hidden);
                }
                return;
            }
            if (form.onsubmit)
                throw new Error("Found onsubmit event handler for the form in " + this.content_pane.tagName + "#" + this.content_pane.id + 
                                "\nYou must delete onsubmit for it.");
            Event.observe(form, "submit", this.submit_edit_form.bindAsEventListener(this), true);
            form.onsubmit = "return false;"
        }
    },

    submit_edit_form: function(event){
        var form = Event.element(event);
        var redirection = null;
        var redirection_elements = form.getElementsByClassName("redirect_to");
        if (redirection_elements.length > 0){
            var redirection_element = redirection_elements[0];
            redirection = redirection_element.className.gsub("redirect_to", "").strip();
        }
        var params = Form.serialize(form);
        params = "redirection=" + (redirection || this.edit_redirection || "show") + "&" + params;
        if (this.content_pane && this.content_pane.id)
          params = params  + "&item_pane_id=" + this.content_pane.id;
        new Ajax.Updater(this.content_pane, form.action, 
                         {asynchronous:true, evalScripts:true, parameters: params,
                          onComplete: this.initialize_contents.bind(this)});
        Event.stop(event);
        return false;
    },

    get_form: function(){
        var forms = this.content_pane.getElementsByTagName("FORM");
        return (forms.length > 0) ? forms[0] : null;
    },

    is_new_record: function(){
        var form = this.get_form();
        if (!form)
            return false;
        return !form._method || (form["_method"].value != "put");
    },
    
    click_link_to_edit_cancel: function(event){
        if (!this.url_to_edit_cancel)
            throw new Error("No url to cancel edit");
        new Ajax.Updater(this.content_pane, this.url_to_edit_cancel,
                         {method: 'get', asynchronous:true, evalScripts:true,
                          onComplete: this.update_contents.bind(this)});
    },
    
    click_link_to_edit: function(event){
        if (!this.url_to_edit)
            throw new Error("No url to edit");
        new Ajax.Updater(this.content_pane, this.url_to_edit,
                         {method: 'get', asynchronous:true, evalScripts:true,
                          onComplete: this.update_contents.bind(this)});
    }
}
Object.extend(PartialResource.Editable.prototype, PartialResource.Base.prototype);
Object.extend(PartialResource.Editable.prototype, PartialResource.Editable.SubmittableMethods);
Object.extend(PartialResource.Editable.prototype, {
    has_one: function(controller, attributes){
        return new PartialResource.EditableHasOne(this, controller, attributes);
    },
    
    has_many: function(controller, attributes){
        return new PartialResource.EditableHasMany(this, controller, attributes);
    }
});
PartialResource.EditableHasOne = Class.create();
Object.extend(PartialResource.EditableHasOne.prototype, PartialResource.Base.prototype);
Object.extend(PartialResource.EditableHasOne.prototype, PartialResource.Editable.SubmittableMethods);
Object.extend(PartialResource.EditableHasOne.prototype, {
});
PartialResource.EditableHasMany = Class.create();
Object.extend(PartialResource.EditableHasMany.prototype, PartialResource.Base.prototype);
Object.extend(PartialResource.EditableHasMany.prototype, PartialResource.HasManyMethods);
Object.extend(PartialResource.EditableHasMany.prototype, {
    new_item: function(pane){
        return new PartialResource.EditableHasManyItem(this, this.controller, {
            content_pane: pane,
            field_values: this.field_values
        });
    },

    click_link_to_add: function(event){
        var new_pane = document.createElement("DIV");
        new_pane.id = "new_pane" + (new Date).getTime();
        Element.addClassName(new_pane, this.record_pane_class());
        this.content_pane.appendChild(new_pane);
        var item = this.add_new_item(new_pane);
        new Ajax.Updater(new_pane, 
                         "/" + this.controller + "/new?submittable=true", 
                         { method: 'get', evalScripts: true, 
                           onComplete: item.activate.bind(item)});
    }
});
PartialResource.EditableHasManyItem = Class.create();
Object.extend(PartialResource.EditableHasManyItem.prototype, PartialResource.Base.prototype);
Object.extend(PartialResource.EditableHasManyItem.prototype, PartialResource.Editable.SubmittableMethods);
Object.extend(PartialResource.EditableHasManyItem.prototype, {
    initialize_contents: function(){
        this.update_contents();
        this.modify_field_value();
    },

    modify_field_value: function(){
        var form = this.get_form();
        if (!form) return;
        if (!this.is_new_record()) return;
        if (!this.field_values) return;
        for(var field_name in this.field_values){
            var field = form[field_name];
            if (field)
                field.value = this.field_values[field_name];
        }
    },

    click_link_to_destroy: function(event){
        var form = this.get_form();
        if (form) {
            if (this.is_new_record()) {
                this.content_pane.remove();
            } else {
                new Ajax.Request(this.url_to_destroy, {
                    method: 'post',
                    parameters: "redirection=render_null&_method=delete&authenticity_token=" + form["authenticity_token"].value,
                    onComplete: this.content_pane.remove.bind(this.content_pane)
                });
            }
        } else {
            this.ajax_delete(this.url_to_destroy, this.content_pane);
        }
    }
});
