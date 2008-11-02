var JsCookie = {
    get: function(key){
        var cookie_items = document.cookie.split(";");
        for(var i=0; i<cookie_items.length; i++){
            var name_value = cookie_items[i].split("=", 2);
            if (name_value.length == 1)
                return null;
            if (name_value[0].strip() == key) {
                return name_value[1];
            }
        }
        return null;
    },

    set: function(key, value, expires_at){
        document.cookie = key + "=" + value + 
            (expires_at == true ? ";expires=Thu, 1 Jan 2030 00:00:00 GMT" : 
             expires_at ? ";expires=" + expires_at.toGMTString() : "");
    },

    checkbox: function(checkbox, key, expires_at){
        checkbox = $(checkbox);
        console.log(this.get(key));
        checkbox.checked = (this.get(key) == "true");
        Event.observe(checkbox, "click", function(){
            this.set(key, checkbox.checked, expires_at);
        }.bindAsEventListener(this));
    }
};

var Verboseable = {
    apply: function(object, block){
        var copyMethods = function(obj, source){
            for (var property in source){
                obj[property] = source[property];
            }
        };
        var source = Verboseable.Methods;
        copyMethods(object, source);
        if (object.prototype)
            copyMethods(object.prototype, source);
        return object;
    },

    Methods: {
        loadVerboseCookie: function(key){
            var loadCookie = function(key){
                var value = JsCookie.get(key || "verbose");
                if (value)
                    this.verbose = value.match(/^on$|^true$/i);
            };
            loadCookie.call(this, key);
            if (this.prototype)
                loadCookie.call(this.prototype, key);
            return this;
        },

        logIfVerbose: function(){
            if (this.verbose)
                this.log.apply(this, arguments);
        },

        log: function(){
            if (!window["console"])
                return;
            var l = arguments.length;
            for(var i=0; i<l; i++){
                var arg = arguments[i];
                if ((i == (l - 1)) && (arg.constructor == Function)){
                    arg();
                } else {
                    console.log(arg);
                }
            }
        }
    }
};
