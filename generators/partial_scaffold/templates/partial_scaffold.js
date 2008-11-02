Object.extend(Function.prototype, {
    bindWithStop: function() {
        var __method = this, args = $A(arguments), object = args.shift();
        return function(event) {
            try{
                var result = __method.apply(object, [event || window.event].concat(args));
            } finally {
                Event.stop(event);
            }
            return result;
        }
    }
});

Object.extend(Element.ClassNames.prototype, {
    getValue: function(key){
        var regexp = new RegExp("^" + key + ":");
        var className = $A(this).detect(function(name){return name.match(regexp);});
        return className ? className.sub(regexp, '') : null;
    },
    
    setValue: function(key, value){
        var regexp = new RegExp("^" + key + ":");
        var className = $A(this).detect(function(name){return name.match(regexp);});
        if (className)
            this.remove(className)
        this.add(key + ":" + value);
        return value;
    }
});

Object.extend(Element.Methods, {
    getClassValue: function(element, key){
        if (!(element = $(element))) return;
        var classNames = new Element.ClassNames(element);
        return classNames.getValue(key);
    },

    setClassValue: function(element, key, value){
        if (!(element = $(element))) return;
        var classNames = new Element.ClassNames(element);
        return classNames.setValue(key, value);
    },

    getAncestorByClassName: function(element, className){
        var ancestors = $A(Element.ancestors(element));
        for(var i=0; i<ancestors.length; i++){
            if (Element.hasClassName(ancestors[i], className)){
                return ancestors[i];
            }
        }
        return null;
    },

    getAncestorByTagName: function(element, tagName){
        var ancestors = $A(Element.ancestors(element));
        var regExp = new RegExp(tagName, 'i');
        for(var i=0; i<ancestors.length; i++){
            if (ancestors[i].tagName.match(regExp)){
                return ancestors[i];
            }
        }
        return null;
    }
});
$A(['getClassValue', 'setClassValue', 
    'getAncestorByClassName', 'getAncestorByTagName']).each(function(m){
    Element[m] = Element.Methods[m];
});


PartialScaffold = Class.create();
Verboseable.apply(PartialScaffold).
    loadVerboseCookie("PartialScaffold.verbose").
    logIfVerbose("PartialScaffold loading...");

Object.extend(PartialScaffold.prototype, {
    initialize: function(auth_token_param, options){
        this.auth_token_param = auth_token_param;
        this.options = Object.extend({}, options || {});
        this.partial_base_class = this.options["partial_base_class"] || "partial_base";
        this.partial_group_class = this.options["partial_group_class"] || "partial_group";
        this.partial_actions_class = this.options["partial_actions_class"] || "partial_actions";
        this.partial_association_class = this.options["partial_association_class"] || "partial_association";
        this.partial_association_to_base_class = this.options["partial_association_to_base"] || "partial_association_to";
    },

    bind_with_action_links: function(area, block_by_link_class){
        var links = area.getElementsByClassName("action");
        for(var i=0; i<links.length; i++){
            var link = links[i];
            this.logIfVerbose(link);
            var class_names = Element.classNames(link);
            if (class_names.include("prepared"))
                continue;
            class_names = class_names.toArray();
            for(var j=0; j<class_names.length; j++){
                var class_name = class_names[j];
                if (!class_name.match(/^link_to_/)) 
                    continue;
                var method_name = class_name;
                var method = this[method_name];
                if (method == null){
                    alert(method_name + " isn't defined.");
                    throw new Error(method_name + " isn't defined.");
                    continue;
                }
                link.onClick = "";
                link.removeAttribute('onclick');
                Event.observe(link, "click", method.bindWithStop(this), true);
                Element.addClassName(link, "prepared");
                if (block_by_link_class){
                    block = block_by_link_class[class_name];
                    if (block)
                        block(link);
                }
            }
        }
    },

    bind_form: function(form, method){
        if (!form) {
            var msg = "form not found";
            throw new Error(msg);
            alert(msg);
            return;
        }
        var class_names = Element.classNames(form);
        if (class_names.include("prepared"))
            return;
        this.logIfVerbose(form);
        Event.observe(form, "submit", this[method].bindWithStop(this));
        Element.addClassName(form, "prepared");
    },

    inc_cascade_count: function(link){
        var classNames = new Element.ClassNames(link);
        var value = classNames.getValue("cascade_count");
        value = Number(value);
        classNames.setValue("cascade_count", value + 1);
        return value;
    },

    check_visible_by_cascade_count_max: function(pane){
        this.logIfVerbose("check_visible_by_cascade_count_max");
        this.logIfVerbose(pane);
        var pane = $(pane);
        var partial_association = Element.hasClassName(pane, this.partial_association_class) ? pane :
            Element.hasClassName(pane, this.partial_group_class) ? Element.getAncestorByClassName(pane, this.partial_association_class) :  
            Element.hasClassName(pane, this.partial_base_class) ? Element.getAncestorByClassName(pane, this.partial_association_class) : 
            Element.hasClassName(pane, this.partial_actions_class) ? Element.getAncestorByClassName(pane, this.partial_association_class) :null;
        if (partial_association == null)
            return ;
        partial_association = $(partial_association);
        var target_class_name =  this.partial_association_to_base_class + ':' + partial_association.id;
        var targets = $(partial_association).getElementsByClassName(target_class_name);
        var partial_associated_actions_array = [];
        var partial_associated_groups = [];
        for(var i=0; i<targets.length; i++){
            var target = $(targets[i]);
            var dest = target.hasClassName(this.partial_actions_class) ? 
                partial_associated_actions_array : partial_associated_groups;
            dest.push(target);
        }
        var partial_associated_groups_length = partial_associated_groups.length;
        for(var i=0; i<partial_associated_actions_array.length; i++){
            var partial_associated_actions = $(partial_associated_actions_array[i]);
            var links = partial_associated_actions.getElementsByClassName('link_to_new');
            for(var j=0; j<links.length; j++){
                var link = $(links[j]);
                var cascade_count_max = Element.getClassValue(link, "cascade_count_max");
                if (cascade_count_max != null){
                    cascade_count_max = Number(cascade_count_max);
                    if (partial_associated_groups_length >= cascade_count_max){
                        link.hide();
                    } else {
                        link.show();
                    }
                }
            }
        }
    },

    setup_base_pane: function(partial_base, block_by_link_class){
        if (partial_base == null)
            throw new Error("no " + this.partial_base_class + " specified for setup_base_pane.");
        this.bind_with_action_links(partial_base, block_by_link_class);
        this.check_visible_by_cascade_count_max(partial_base);
    },

    link_to_new: function(event){
        var link = Event.element(event);
        var partial_association = Element.getAncestorByClassName(link, 'partial_association');
        var partial_group = document.createElement('div');
        Element.addClassName(partial_group, this.partial_group_class);
        Element.addClassName(partial_group, this.partial_association_to_base_class + ":" + partial_association.id);
        Element.insert(link.parentNode, {before: partial_group});
        var parameters = ""
        var cascade_name_base = Element.getClassValue(link, "cascade_name_base");
        if (cascade_name_base) {
            var cascade_name = cascade_name_base + "[" + this.inc_cascade_count(link)  + "]";
            parameters = parameters + "cascade_name=" + cascade_name;
        } else {
            var cascade_name = Element.getClassValue(link, "cascade_name");
            if (cascade_name)
                parameters = parameters + "cascade_name=" + cascade_name;
        }
        new Ajax.Updater(partial_group, link.href, {
            method: 'get',
            evalScripts: true,
            parameters: parameters,
            onComplete: function(){
                this.check_visible_by_cascade_count_max(partial_association);
            }.bind(this)
        });
    },

    setup_new: function(partial_base, ajax_form){
        this.logIfVerbose("setup_new");
        if (partial_base == null)
            throw new Error("no " + this.partial_base_class + " specified for setup_base_pane.");
        this.bind_with_action_links(partial_base);
        if (ajax_form){
            var form = Element.getAncestorByTagName(partial_base, "form");
            this.bind_form(form, "submit_to_create");
        }
        this.check_visible_by_cascade_count_max(partial_base);
    },

    submit_to_create: function(event){
        var form = Event.element(event);
        var partial_group = Element.getAncestorByClassName(form, this.partial_group_class);
        new Ajax.Updater(partial_group, form.action, {
            method: 'post',
            evalScripts: true,
            parameters: Form.serialize(form)
        });
    },

    link_to_cancel_new: function(event){
        this.logIfVerbose("link_to_cancel_new");
        var link = Event.element(event);
        var partial_group = Element.getAncestorByClassName(link, this.partial_group_class);
        var partial_association = Element.getAncestorByClassName(link, this.partial_association_class);
        Element.remove(partial_group);
        this.check_visible_by_cascade_count_max(partial_association);
    },

    setup_show: function(partial_base){
        this.logIfVerbose("setup_show");
        if (partial_base == null)
            throw new Error("no " + this.partial_base_class + " specified for setup_show.");
        this.bind_with_action_links(partial_base);
        this.check_visible_by_cascade_count_max(partial_base);
    },

    link_to_edit: function(event){
        var link = Event.element(event);
        var partial_base = Element.getAncestorByClassName(link, this.partial_base_class);
        new Ajax.Updater(partial_base, link.href, {
            method: 'get',
            evalScripts: true
        });
    },

    link_to_destroy: function(event){
        this.logIfVerbose("link_to_destroy");
        var link = Event.element(event);
        var partial_base = Element.getAncestorByClassName(link, this.partial_base_class);
        var partial_association = Element.getAncestorByClassName(link, this.partial_association_class);
        new Ajax.Updater(partial_base, link.href, {
            method: 'post',
            evalScripts: true,
            parameters: this.auth_token_param + "&_method=delete",
            onComplete: function(){
                var partial_group = Element.getAncestorByClassName(partial_base, this.partial_group_class);
                if (partial_base.innerHTML == ""){
                    Element.remove(partial_group);
                }
                this.check_visible_by_cascade_count_max(partial_association);
            }.bind(this)
        });
    },

    setup_edit: function(form){
        this.logIfVerbose("setup_edit");
        if (form == null)
            throw new Error("no form specified for setup_show.");
        this.bind_with_action_links(form);
        this.bind_form(form, "submit_to_edit");
    },

    link_to_cancel_edit: function(event){
        var link = Event.element(event);
        var partial_base = Element.getAncestorByClassName(link, this.partial_base_class);
        new Ajax.Updater(partial_base, link.href, {
            method: 'get',
            evalScripts: true,
            parameters: "show_partial_base_only=true",
            onComplete: function(){this.setup_show(partial_base);}.bind(this)
        });
    },

    submit_to_edit: function(event) {
        var form = Event.element(event);
        var partial_base = Element.getAncestorByClassName(form, this.partial_base_class);
        new Ajax.Updater(partial_base, form.action, {
            method: 'post',
            evalScripts: true,
            parameters: Form.serialize(form) + "&show_partial_base_only=true",
            onComplete: function(){this.setup_show(partial_base);}.bind(this)
        });
    },

    setup_belongs_to_field: function(field_link){
        this.logIfVerbose("setup_belongs_to_field");
        field_link = $(field_link);
        Element.observe(field_link, 'click', function(event){
            var link = Event.element(event);
            var container = document.createElement('DIV');
            Element.addClassName(container, 'list_for_belongs_to_field');
            Element.insert(link, {after: container});
            new Ajax.Updater(container, link.href, {
                method: 'get',
                evalScripts: true,
                parameters: "selection=true",
                onComplete: function(){
                    new Draggable(container);
                    Element.absolutize(container);
                    this.setup_selections(container, link);
                }.bind(this)
            });
        }.bindWithStop(this), true);
    },

    setup_selections: function(container, source_link){
        this.logIfVerbose("setup_selection");
        var links = document.getElementsByClassName('link_to_selection', container);
        for(var i=0; i<links.length; i++){
            var link = links[i];
            Element.addClassName(link, 'prepared');
            Event.observe(link, "click", function(event){
                var link = Event.element(event);
                var selection_id = $(link.parentNode).getElementsByClassName('selection_id')[0].innerHTML;
                var selection_name = $(link.parentNode).getElementsByClassName('selection_name')[0].innerHTML;
                var field_hidden = $(source_link.parentNode).getElementsByClassName('belongs_to_field_hidden')[0];
                var field_name = $(source_link.parentNode).getElementsByClassName('belongs_to_field_name')[0];
                field_hidden.value = selection_id;
                field_name.innerHTML = selection_name;
                if (JsCookie.get("close_on_click_selection") == "true")
                    Element.remove(container);
            }.bindWithStop(this), true);
        }
        var links = container.getElementsByTagName('A');
        for(var i=0; i<links.length; i++){
            if (Element.hasClassName('prepared'))
                continue;
            links[i].target = "_blank";
        }
        var footer = document.createElement("div")
        Element.addClassName(footer, "selection_footer");
        Element.insert(container, {bottom: footer});
        var close_link = document.createElement('a');
        close_link.href = "javascript:void(0)";
        close_link.innerHTML = "Close"
        close_link.onclick = function(){ Element.remove(container); };
        Element.insert(footer, close_link);
        var checkbox_id = "close_on_select_" + new Date().getTime();
        var checkbox = document.createElement("input");
        checkbox.type = "checkbox";
        checkbox.id = checkbox_id;
        Element.insert(footer, checkbox);
        JsCookie.checkbox(checkbox, "close_on_click_selection", true);
        var checkbox_label = document.createElement("label");
        checkbox_label.htmlFor = checkbox_id;
        checkbox_label.innerHTML = "close on click Select";
        Element.insert(footer, checkbox_label);
    }

});

PartialScaffold.logIfVerbose("PartialScaffold loaded!");
